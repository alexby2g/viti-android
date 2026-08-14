import 'package:flutter/material.dart';

import '../../core/ui/viti_ui.dart';
import '../data/viti_repository.dart';

class GuideModuleScreen extends StatefulWidget {
  const GuideModuleScreen({required this.repository, required this.role, super.key});

  final VitiRepository repository;
  final String role;

  @override
  State<GuideModuleScreen> createState() => _GuideModuleScreenState();
}

class _GuideModuleScreenState extends State<GuideModuleScreen> {
  bool loading = true;
  int active = 0;

  bool get client => widget.role == 'cliente';
  bool get support => widget.role == 'soporte';

  List<_GuideStep> get steps {
    if (support) {
      return const [
        _GuideStep(Icons.support_agent, 'Revisar trabajo asignado', 'Solo aparecen solicitudes, proyectos y casos delegados a tu cuenta.'),
        _GuideStep(Icons.fact_check_outlined, 'Atender el caso', 'Revisa prioridad, empresa y estado antes de realizar cambios.'),
        _GuideStep(Icons.forum_outlined, 'Coordinar por mensajes', 'Usa únicamente las conversaciones que AGR Studio haya asignado.'),
        _GuideStep(Icons.task_alt, 'Actualizar el estado', 'Registra el avance del caso para conservar trazabilidad.'),
      ];
    }
    if (!client) {
      return const [
        _GuideStep(Icons.move_to_inbox, 'Recibir solicitud', 'Revisa cliente, empresa, cuestionario y documentos.'),
        _GuideStep(Icons.manage_search, 'Evaluar viabilidad', 'Define problema, alcance, módulos, tiempo y riesgos.'),
        _GuideStep(Icons.request_quote_outlined, 'Definir propuesta', 'Establece plan, precio, forma de pago y fechas.'),
        _GuideStep(Icons.account_tree_outlined, 'Convertir en proyecto', 'Crea el proyecto y asigna responsables.'),
        _GuideStep(Icons.terminal, 'Desarrollar y publicar avances', 'Actualiza progreso, módulos y decisiones visibles.'),
        _GuideStep(Icons.science_outlined, 'Habilitar beta', 'La beta es una decisión manual y no equivale a entrega.'),
        _GuideStep(Icons.payments_outlined, 'Controlar pagos', 'Revisa comprobantes antes de modificar saldos.'),
        _GuideStep(Icons.verified_user_outlined, 'Entregar y dar soporte', 'Habilita acceso cuando producción, pago y entrega correspondan.'),
      ];
    }
    return const [
      _GuideStep(Icons.person_add_alt, 'Crear tu cuenta', 'Tu perfil identifica quién solicita el trabajo.'),
      _GuideStep(Icons.assignment_add, 'Crear una solicitud', 'Cada idea nueva genera una solicitud independiente.'),
      _GuideStep(Icons.fact_check_outlined, 'Completar el formulario', 'Describe problema, funciones, usuarios y prioridades.'),
      _GuideStep(Icons.manage_search, 'Revisión de AGR Studio', 'El equipo organiza el alcance y puede escribirte por el buzón.'),
      _GuideStep(Icons.account_tree_outlined, 'Proyecto y desarrollo', 'Consulta progreso, fechas, avances y archivos.'),
      _GuideStep(Icons.science_outlined, 'Beta y pruebas', 'Valida el sistema antes de la entrega definitiva.'),
      _GuideStep(Icons.verified, 'Entrega y soporte', 'La aplicación queda habilitada y registrada para soporte.'),
    ];
  }

  @override
  void initState() {
    super.initState();
    _resolveActiveStep();
  }

  Future<void> _resolveActiveStep() async {
    if (!mounted) return;
    setState(() => loading = true);
    try {
      if (client) {
        final requests = await widget.repository.clientRequests();
        if (requests.isEmpty) {
          active = 1;
        } else {
          final state = '${requests.first['estado'] ?? ''}';
          active = switch (state) {
            'borrador' => 2,
            'en_revision' => 3,
            'aprobada' => 4,
            'convertida' => 4,
            _ => 1,
          };
          if (state == 'convertida') {
            final project = await widget.repository.clientProject();
            final progress = int.tryParse('${project?['progreso'] ?? 0}') ?? 0;
            final app = project?['aplicacion'];
            if (app is Map<String, dynamic> && app['acceso_cliente'] == true) {
              active = 6;
            } else if ('${(app is Map<String, dynamic>) ? app['entorno'] : ''}' == 'beta' || progress >= 80) {
              active = 5;
            }
          }
        }
      } else if (!support) {
        final dashboard = await widget.repository.adminDashboard();
        final summary = dashboard['resumen'];
        if (summary is Map<String, dynamic>) {
          if ((int.tryParse('${summary['aplicaciones_pendientes_entrega'] ?? 0}') ?? 0) > 0) {
            active = 7;
          } else if ((int.tryParse('${summary['proyectos_activos'] ?? 0}') ?? 0) > 0) {
            active = 4;
          } else if ((int.tryParse('${summary['solicitudes_activas'] ?? 0}') ?? 0) > 0) {
            active = 1;
          }
        }
      }
    } catch (_) {
      active = 0;
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = steps;
    final title = support ? 'Guía de soporte' : client ? 'Guía de mi proyecto' : 'Guía de operación';
    final subtitle = support
        ? 'Una ruta breve para trabajar únicamente sobre lo que te fue asignado.'
        : client
            ? 'Desde tu solicitud hasta la entrega, con la etapa actual resaltada.'
            : 'Mapa operativo de solicitudes, proyectos, pagos, aplicaciones y entrega.';

    return RefreshIndicator(
      onRefresh: _resolveActiveStep,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(26, 24, 26, 38),
        children: [
          VitiPageHeader(title: title, subtitle: subtitle, actions: [IconButton.filledTonal(onPressed: _resolveActiveStep, tooltip: 'Actualizar guía', icon: const Icon(Icons.refresh))]),
          const SizedBox(height: 18),
          if (loading) const LinearProgressIndicator(),
          if (loading) const SizedBox(height: 14),
          VitiPanel(
            selected: true,
            tone: VitiTone.info,
            child: Row(children: [Icon(client ? Icons.explore_outlined : support ? Icons.support_agent : Icons.route_outlined, color: vitiToneColor(context, VitiTone.info)), const SizedBox(width: 12), Expanded(child: Text(client ? 'El paso resaltado representa la etapa más cercana a tu situación actual.' : support ? 'El flujo mantiene tu trabajo aislado de la administración global.' : 'El paso resaltado marca el foco operativo que VITI detecta ahora.', style: const TextStyle(fontWeight: FontWeight.w700)))]),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              if (!client && !support && constraints.maxWidth >= 1180) {
                return Wrap(spacing: 12, runSpacing: 12, children: [for (var index = 0; index < items.length; index++) SizedBox(width: (constraints.maxWidth - 36) / 4, child: _StepCard(step: items[index], number: index + 1, active: index == active, done: false))]);
              }
              return Column(children: [for (var index = 0; index < items.length; index++) ...[_StepCard(step: items[index], number: index + 1, active: index == active, done: client && index < active), if (index < items.length - 1) Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Icon(Icons.south, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant))]]);
            },
          ),
          const SizedBox(height: 18),
          VitiPanel(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Estados clave', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              Wrap(spacing: 6, runSpacing: 6, children: const [VitiStatusBadge('Borrador'), VitiStatusBadge('En revisión', tone: VitiTone.warning), VitiStatusBadge('Aprobada', tone: VitiTone.success), VitiStatusBadge('Convertida', tone: VitiTone.primary), VitiStatusBadge('Beta', tone: VitiTone.info), VitiStatusBadge('Finalizada', tone: VitiTone.success), VitiStatusBadge('Entregada', tone: VitiTone.success)]),
              const SizedBox(height: 12),
              Text('Beta, finalización técnica, entrega y suscripción son estados separados. El vencimiento de una prueba no convierte automáticamente una aplicación en producción.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.35)),
            ]),
          ),
        ],
      ),
    );
  }
}

class _GuideStep {
  const _GuideStep(this.icon, this.title, this.text);
  final IconData icon;
  final String title;
  final String text;
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.step, required this.number, required this.active, required this.done});
  final _GuideStep step;
  final int number;
  final bool active;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final tone = done ? VitiTone.success : active ? VitiTone.primary : VitiTone.neutral;
    final color = vitiToneColor(context, tone);
    return VitiPanel(
      selected: active || done,
      tone: tone,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: color.withValues(alpha: .13), borderRadius: BorderRadius.circular(14)), child: Icon(done ? Icons.check : step.icon, color: color)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('PASO $number', style: TextStyle(fontSize: 9, letterSpacing: 1.1, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurfaceVariant)), const SizedBox(height: 4), Text(step.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)), const SizedBox(height: 5), Text(step.text, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.35))])),
          if (active) const VitiStatusBadge('Ahora', tone: VitiTone.primary),
        ],
      ),
    );
  }
}
