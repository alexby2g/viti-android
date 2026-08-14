import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import 'electrofrio_repository.dart';
import 'technical_workflow_dialogs.dart';

class ElectrofrioOrderWorkspace extends StatefulWidget {
  const ElectrofrioOrderWorkspace({required this.repository, required this.initialOrder, required this.canManage, required this.hasInventory, required this.hasPayments, required this.hasWarranty, required this.onEditAppointment, required this.onChanged, super.key});

  final ElectrofrioRepository repository;
  final Map<String, dynamic> initialOrder;
  final bool canManage;
  final bool hasInventory;
  final bool hasPayments;
  final bool hasWarranty;
  final ValueChanged<Map<String, dynamic>> onEditAppointment;
  final VoidCallback onChanged;

  @override
  State<ElectrofrioOrderWorkspace> createState() => _ElectrofrioOrderWorkspaceState();
}

class _ElectrofrioOrderWorkspaceState extends State<ElectrofrioOrderWorkspace> {
  static const stages = ['cita', 'diagnostico', 'propuesta', 'servicio', 'cerrada'];
  late Map<String, dynamic> order;
  bool busy = false;

  @override
  void initState() { super.initState(); order = Map<String, dynamic>.from(widget.initialOrder); }

  String get stage => '${order['etapa'] ?? 'cita'}';
  bool get closed => stage == 'cerrada';
  bool get accepted => '${order['decision_cliente']}' == 'aceptado';
  bool get pendingDecision => !const {'aceptado', 'rechazado'}.contains('${order['decision_cliente']}');

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(children: [
      Container(
        padding: const EdgeInsets.fromLTRB(22, 18, 12, 16),
        decoration: BoxDecoration(color: colors.surfaceContainerHighest, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
        child: Row(children: [
          CircleAvatar(backgroundColor: colors.primaryContainer, foregroundColor: colors.onPrimaryContainer, child: const Icon(Icons.ac_unit)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${_text(order['codigo'], 'Orden')} · ${_text(order['cliente_nombre'], 'Cliente')}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)), Text('${_stage(stage)} · ${_equipment(order)}', style: TextStyle(color: colors.onSurfaceVariant))])),
          if (busy) const Padding(padding: EdgeInsets.only(right: 10), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
          IconButton(onPressed: busy ? null : () => Navigator.pop(context), icon: const Icon(Icons.close)),
        ]),
      ),
      Expanded(child: ListView(padding: const EdgeInsets.all(22), children: [
        _flow(), const SizedBox(height: 14), _actions(), const SizedBox(height: 14), _stats(), const SizedBox(height: 14),
        _section('Cita y diagnóstico', Icons.calendar_month_outlined, [
          _field('Fecha', _date(order['fecha_cita'])), _field('Hora', _text(order['hora_cita'], 'Sin hora')), _field('Dirección', _text(order['direccion_servicio'], 'Sin dirección')), _field('Referencia', _text(order['referencia_ubicacion'], 'Sin referencia')), _field('Técnico', _text(order['tecnico_nombre'], 'Sin asignar')), _field('Problema', _text(order['problema_reportado'], 'Sin detalle')), _field('Diagnóstico', _text(order['diagnostico'], 'Pendiente')),
        ]),
        const SizedBox(height: 12),
        _section('Propuesta y decisión', Icons.handshake_outlined, [
          _field('Propuesta', _text(order['propuesta'], 'Pendiente')), _field('Decisión', _decision(order)), if (_text(order['motivo_rechazo'], '').isNotEmpty) _field('Motivo de rechazo', _text(order['motivo_rechazo'], '')),
        ]),
        if (widget.hasInventory) ...[const SizedBox(height: 12), _materials()],
        const SizedBox(height: 12),
        _section('Servicio y garantía', Icons.home_repair_service_outlined, [
          _field('Trabajo realizado', _text(order['trabajo_realizado'], 'Pendiente')), _field('Recomendaciones', _text(order['recomendaciones'], 'Sin recomendaciones')), if (widget.hasWarranty) _field('Garantía', _warranty(order)), if (widget.hasWarranty && _text(order['condiciones_garantia'], '').isNotEmpty) _field('Condiciones', _text(order['condiciones_garantia'], '')),
        ]),
        if (widget.hasPayments) ...[const SizedBox(height: 12), _payments()],
      ])),
    ]);
  }

  Widget _flow() {
    final colors = Theme.of(context).colorScheme;
    final current = stages.indexOf(stage);
    final rejected = closed && '${order['decision_cliente']}' == 'rechazado';
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [const Expanded(child: Text('Flujo Electrofrío', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900))), Chip(label: Text(rejected ? 'Rechazado' : _stage(stage)))]),
      const SizedBox(height: 14),
      if (rejected) Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: colors.errorContainer, borderRadius: BorderRadius.circular(12)), child: Text('El cliente rechazó la propuesta. La atención quedó cerrada sin ejecutar el servicio.', style: TextStyle(color: colors.onErrorContainer, fontWeight: FontWeight.w700)))
      else SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [for (var i=0;i<stages.length;i++) ...[_step(stages[i], i<current, i==current), if(i<stages.length-1) Container(width: 34,height:2,color:i<current?colors.primary:colors.outlineVariant)]])),
    ])));
  }

  Widget _step(String value, bool done, bool current) {
    final colors = Theme.of(context).colorScheme;
    return Container(width: 135, padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: current ? colors.primaryContainer : done ? colors.secondaryContainer : colors.surfaceContainer, borderRadius: BorderRadius.circular(12), border: current ? Border.all(color: colors.primary) : null), child: Row(children: [Icon(done ? Icons.check_circle : current ? Icons.radio_button_checked : Icons.radio_button_unchecked, size:18), const SizedBox(width:7), Expanded(child: Text(_stage(value), style: const TextStyle(fontSize:11,fontWeight:FontWeight.w700)))]));
  }

  Widget _actions() {
    if (!widget.canManage) return Card(child: Padding(padding: const EdgeInsets.all(16), child: Text('Acceso de consulta. Los datos se sincronizan con la misma operación de Electrofrío.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))));
    final actions=<Widget>[
      OutlinedButton.icon(onPressed: busy||closed?null:()=>widget.onEditAppointment(order), icon: const Icon(Icons.edit_calendar_outlined), label: const Text('Editar cita')),
      if(!closed && const {'cita','diagnostico','propuesta'}.contains(stage)) FilledButton.icon(onPressed: busy?null:_diagnose, icon: const Icon(Icons.fact_check_outlined), label: Text(_text(order['propuesta'],'').isEmpty?'Diagnosticar y proponer':'Editar diagnóstico')),
      if(!closed && _text(order['diagnostico'],'').isNotEmpty && _text(order['propuesta'],'').isNotEmpty && pendingDecision) FilledButton.icon(onPressed: busy?null:_decisionDialog, icon: const Icon(Icons.how_to_reg_outlined), label: const Text('Registrar decisión')),
      if(!closed && accepted && stage=='servicio') FilledButton.icon(onPressed: busy?null:_finish, icon: const Icon(Icons.task_alt), label: const Text('Finalizar servicio')),
      if(widget.hasInventory && !closed && accepted) OutlinedButton.icon(onPressed: busy?null:_addMaterial, icon: const Icon(Icons.inventory_2_outlined), label: const Text('Usar material')),
      if(widget.hasPayments && _num(order['saldo'])>0) OutlinedButton.icon(onPressed: busy?null:_paymentDialog, icon: const Icon(Icons.payments_outlined), label: Text('Registrar pago · ${_money(order['saldo'])} Bs')),
    ];
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Acciones disponibles', style: TextStyle(fontSize:17,fontWeight:FontWeight.w900)), const SizedBox(height:12), Wrap(spacing:8,runSpacing:8,children:actions)])));
  }

  Widget _stats()=>Wrap(spacing:10,runSpacing:10,children:[_mini('Etapa',_stage(stage),Icons.flag_outlined),_mini('Técnico',_text(order['tecnico_nombre'],'Sin asignar'),Icons.engineering_outlined),_mini('Decisión',_decision(order),Icons.how_to_reg_outlined),if(widget.hasPayments)_mini('Total','${_money(order['total'])} Bs',Icons.receipt_long_outlined),if(widget.hasPayments)_mini('Saldo','${_money(order['saldo'])} Bs',Icons.payments_outlined)]);
  Widget _mini(String label,String value,IconData icon)=>Container(width:210,padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:Theme.of(context).colorScheme.surfaceContainer,borderRadius:BorderRadius.circular(14)),child:Row(children:[CircleAvatar(radius:18,child:Icon(icon,size:18)),const SizedBox(width:10),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(label,style:TextStyle(fontSize:11,color:Theme.of(context).colorScheme.onSurfaceVariant)),Text(value,maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(fontWeight:FontWeight.w800))]))]));
  Widget _section(String title,IconData icon,List<Widget> children)=>Card(child:Padding(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Icon(icon),const SizedBox(width:9),Text(title,style:const TextStyle(fontSize:17,fontWeight:FontWeight.w900))]),const SizedBox(height:14),Wrap(spacing:18,runSpacing:14,children:children)])));
  Widget _field(String label,String value)=>SizedBox(width:310,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(label,style:TextStyle(fontSize:11,fontWeight:FontWeight.w700,color:Theme.of(context).colorScheme.onSurfaceVariant)),const SizedBox(height:3),SelectableText(value,style:const TextStyle(fontWeight:FontWeight.w600))]));

  Widget _materials() {
    final items=_list(order['materiales']);
    return Card(child:Padding(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[const Icon(Icons.inventory_2_outlined),const SizedBox(width:9),const Expanded(child:Text('Materiales utilizados',style:TextStyle(fontSize:17,fontWeight:FontWeight.w900))),if(widget.canManage&&!closed&&accepted)TextButton.icon(onPressed:busy?null:_addMaterial,icon:const Icon(Icons.add),label:const Text('Agregar'))]),
      if(items.isEmpty)Text('No hay materiales registrados.',style:TextStyle(color:Theme.of(context).colorScheme.onSurfaceVariant)),
      for(final item in items)ListTile(contentPadding:EdgeInsets.zero,leading:const CircleAvatar(child:Icon(Icons.build_outlined)),title:Text('${item['material_nombre']??'Material'} · ${item['cantidad']??0} ${item['material_unidad']??''}'),subtitle:Text('Subtotal ${_money(item['subtotal'])} Bs'),trailing:widget.canManage&&!closed?IconButton(onPressed:busy?null:()=>_removeMaterial(_id(item['material_id'])),icon:const Icon(Icons.delete_outline),tooltip:'Quitar material'):null),
    ])));
  }

  Widget _payments() {
    final items=_list(order['pagos']);
    return Card(child:Padding(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[const Icon(Icons.payments_outlined),const SizedBox(width:9),const Expanded(child:Text('Pagos',style:TextStyle(fontSize:17,fontWeight:FontWeight.w900))),if(widget.canManage&&_num(order['saldo'])>0)TextButton.icon(onPressed:busy?null:_paymentDialog,icon:const Icon(Icons.add),label:const Text('Registrar'))]),
      if(items.isEmpty)Text('Aún no hay pagos.',style:TextStyle(color:Theme.of(context).colorScheme.onSurfaceVariant)),
      for(final item in items)ListTile(contentPadding:EdgeInsets.zero,leading:const CircleAvatar(child:Icon(Icons.attach_money)),title:Text('${_money(item['monto'])} Bs · ${_pretty(item['metodo'])}'),subtitle:Text('${_date(item['pagado_at'])}${_text(item['referencia'],'').isNotEmpty?' · ${item['referencia']}':''}')),
    ])));
  }

  Future<void> _diagnose() async {
    final draft=await showDiagnosisProposalForm(context,order:order,showFinancial:widget.hasPayments);
    if(draft==null)return;
    await _run(()async{order=await widget.repository.update('ordenes',_id(order['id']),_orderBody(diagnosis:'${draft['diagnostico']}',proposal:'${draft['propuesta']}',labor:draft.containsKey('costo_servicio')?_nullableNum(draft['costo_servicio']):_nullableNum(order['costo_mano_obra']),discount:draft.containsKey('descuento')?_nullableNum(draft['descuento']):_nullableNum(order['descuento'])));},'Diagnóstico y propuesta guardados.');
  }
  Future<void> _decisionDialog() async { final draft=await showClientDecisionForm(context,order:order);if(draft==null)return;await _run(()async{order=await widget.repository.decideOrder(_id(order['id']),'${draft['decision']}',reason:'${draft['motivo_rechazo']??''}');},draft['decision']=='aceptado'?'Propuesta aceptada. Inicia el servicio.':'Propuesta rechazada. Orden cerrada.'); }
  Future<void> _finish() async { final draft=await showRepairCompletionForm(context,order:order);if(draft==null)return;await _run(()async{order=await widget.repository.finishOrder(_id(order['id']),workDone:'${draft['trabajo_realizado']}',recommendations:'${draft['recomendaciones']??''}',warrantyDays:widget.hasWarranty?_id(draft['garantia_dias']):0,warrantyTerms:widget.hasWarranty?'${draft['condiciones_garantia']??''}':null);},'Servicio finalizado y guardado en historial.'); }

  Future<void> _addMaterial() async {
    List<Map<String,dynamic>> available;
    try{available=await widget.repository.list('materiales');}on ApiException catch(e){if(mounted)_notice(e.message);return;}
    final active=available.where((m)=>m['activo']!=false&&_num(m['stock'])>0).toList(growable:false);
    if(active.isEmpty){_notice('No hay materiales con stock disponible.');return;}
    var materialId=_id(active.first['id']);final quantity=TextEditingController(text:'1');
    final result=await showDialog<Map<String,dynamic>>(context:context,builder:(dialogContext)=>StatefulBuilder(builder:(context,setState)=>AlertDialog(title:const Text('Usar material'),content:SizedBox(width:520,child:Column(mainAxisSize:MainAxisSize.min,children:[DropdownButtonFormField<int>(initialValue:materialId,decoration:const InputDecoration(labelText:'Material',border:OutlineInputBorder()),items:[for(final row in active)DropdownMenuItem(value:_id(row['id']),child:Text('${row['nombre']} · stock ${row['stock']} ${row['unidad']}'))],onChanged:(v)=>setState(()=>materialId=v??materialId)),const SizedBox(height:10),TextField(controller:quantity,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Cantidad',border:OutlineInputBorder()))])),actions:[TextButton(onPressed:()=>Navigator.pop(dialogContext),child:const Text('Cancelar')),FilledButton(onPressed:(){final q=double.tryParse(quantity.text.replaceAll(',','.'));if(q==null||q<=0)return;Navigator.pop(dialogContext,{'material_id':materialId,'cantidad':q});},child:const Text('Registrar'))])));
    quantity.dispose();if(result==null)return;await _run(()async{order=await widget.repository.useMaterial(_id(order['id']),result['material_id'] as int,result['cantidad'] as double);},'Material actualizado en la orden.');
  }
  Future<void> _removeMaterial(int materialId) async { if(materialId<=0)return;await _run(()async{order=await widget.repository.removeMaterial(_id(order['id']),materialId);},'Material retirado de la orden y stock restituido.'); }
  Future<void> _paymentDialog() async { final amount=TextEditingController();final reference=TextEditingController();var method='efectivo';final result=await showDialog<Map<String,dynamic>>(context:context,builder:(dialogContext)=>StatefulBuilder(builder:(context,setState)=>AlertDialog(title:const Text('Registrar pago'),content:SizedBox(width:480,child:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:amount,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:InputDecoration(labelText:'Monto',suffixText:'Bs',helperText:'Saldo ${_money(order['saldo'])} Bs',border:const OutlineInputBorder())),const SizedBox(height:10),DropdownButtonFormField<String>(initialValue:method,decoration:const InputDecoration(labelText:'Método',border:OutlineInputBorder()),items:const [DropdownMenuItem(value:'efectivo',child:Text('Efectivo')),DropdownMenuItem(value:'qr',child:Text('QR')),DropdownMenuItem(value:'transferencia',child:Text('Transferencia')),DropdownMenuItem(value:'tarjeta',child:Text('Tarjeta')),DropdownMenuItem(value:'otro',child:Text('Otro'))],onChanged:(v)=>setState(()=>method=v??method)),const SizedBox(height:10),TextField(controller:reference,decoration:const InputDecoration(labelText:'Referencia',border:OutlineInputBorder()))])),actions:[TextButton(onPressed:()=>Navigator.pop(dialogContext),child:const Text('Cancelar')),FilledButton(onPressed:(){final a=double.tryParse(amount.text.replaceAll(',','.'));if(a==null||a<=0)return;Navigator.pop(dialogContext,{'monto':a,'metodo':method,'referencia':reference.text.trim()});},child:const Text('Registrar'))])));amount.dispose();reference.dispose();if(result==null)return;await _run(()async{await widget.repository.registerPayment(_id(order['id']),result['monto'] as double,'${result['metodo']}',reference:'${result['referencia']}');await _reload();},'Pago registrado.'); }

  Map<String,dynamic> _orderBody({String? diagnosis,String? proposal,double? labor,double? discount})=><String,dynamic>{'cliente_id':_id(order['cliente_id']),'equipo_id':_nullableId(order['equipo_id']),'tecnico_id':_nullableId(order['tecnico_id']),'fecha_cita':_iso(order['fecha_cita']),'hora_cita':_time(order['hora_cita']),'direccion_servicio':_text(order['direccion_servicio'],'Sin dirección'),'referencia_ubicacion':_nullable(order['referencia_ubicacion']),'problema_reportado':_text(order['problema_reportado'],'Sin detalle'),'prioridad':_text(order['prioridad'],'normal'),'diagnostico':diagnosis??_nullable(order['diagnostico']),'propuesta':proposal??_nullable(order['propuesta']),'trabajo_realizado':_nullable(order['trabajo_realizado']),'recomendaciones':_nullable(order['recomendaciones']),'costo_mano_obra':labor??_nullableNum(order['costo_mano_obra']),'descuento':discount??_nullableNum(order['descuento'])};
  Future<void> _reload() async { final rows=await widget.repository.list('ordenes');for(final row in rows){if(_id(row['id'])==_id(order['id'])){order=Map<String,dynamic>.from(row);return;}} }
  Future<void> _run(Future<void> Function() action,String success)async{if(busy)return;setState(()=>busy=true);try{await action();if(!mounted)return;setState((){});_notice(success);widget.onChanged();}on ApiException catch(e){if(mounted)_notice(e.message);}catch(_){if(mounted)_notice('No se pudo completar la operación.');}finally{if(mounted)setState(()=>busy=false);}}
  void _notice(String message)=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(message)));
}

String _stage(String v)=>switch(v){'cita'=>'Cita','diagnostico'=>'Diagnóstico','propuesta'=>'Propuesta','servicio'=>'Servicio','cerrada'=>'Cerrada',_=>_pretty(v)};
String _decision(Map<String,dynamic> o)=>switch('${o['decision_cliente']??'pendiente'}'){'aceptado'=>'Aceptada','rechazado'=>'Rechazada',_=>'Pendiente'};
String _equipment(Map<String,dynamic> o){final parts=[_text(o['equipo_tipo'],''),_text(o['equipo_marca'],''),_text(o['equipo_modelo'],'')].where((e)=>e.isNotEmpty).toList();return parts.isEmpty?'Sin equipo asociado':parts.join(' ');}
String _warranty(Map<String,dynamic> o){final days=_id(o['garantia_dias']);return days<=0?'Sin garantía':'$days días · ${_date(o['garantia_inicio'])} a ${_date(o['garantia_fin'])}';}
List<Map<String,dynamic>> _list(dynamic v)=>v is List?v.whereType<Map<String,dynamic>>().toList(growable:false):const <Map<String,dynamic>>[];
int _id(dynamic v)=>int.tryParse('${v??0}')??0;int? _nullableId(dynamic v){final x=_id(v);return x>0?x:null;}double _num(dynamic v)=>double.tryParse('${v??0}')??0;double? _nullableNum(dynamic v){final s='${v??''}'.trim().replaceAll(',','.');return s.isEmpty?null:double.tryParse(s);}String _money(dynamic v)=>_num(v).toStringAsFixed(2);String _text(dynamic v,String f)=>v==null||v.toString().trim().isEmpty?f:v.toString();String _pretty(dynamic v)=>_text(v,'Sin estado').replaceAll('_',' ');String? _nullable(dynamic v){final s='${v??''}'.trim();return s.isEmpty?null:s;}String _iso(dynamic v){final d=DateTime.tryParse('${v??''}');return d?.toIso8601String().split('T').first??DateTime.now().toIso8601String().split('T').first;}String? _time(dynamic v){final s='${v??''}'.trim();if(s.isEmpty)return null;return s.length>=5?s.substring(0,5):s;}String _date(dynamic v){final d=DateTime.tryParse('${v??''}')?.toLocal();if(d==null)return'No definida';String p(int n)=>n.toString().padLeft(2,'0');return'${p(d.day)}/${p(d.month)}/${d.year}';}
