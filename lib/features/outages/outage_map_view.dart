import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/entities/entities.dart';

class OutageMapView extends StatefulWidget {
  const OutageMapView({super.key, required this.snapshot});
  final DemoSnapshot snapshot;

  @override
  State<OutageMapView> createState() => _OutageMapViewState();
}

class _OutageMapViewState extends State<OutageMapView> {
  String? _selected;

  static const _sectors = <(String, String, double, double)>[
    ('Santo Domingo Este', 'SDE-14', 0.68, 0.42),
    ('Los Alcarrizos', 'LAC-07', 0.40, 0.30),
    ('San Cristóbal', 'SCR-03', 0.34, 0.55),
    ('Baní', 'BAN-02', 0.30, 0.70),
    ('Barahona', 'BAR-01', 0.22, 0.84),
  ];

  @override
  Widget build(BuildContext context) {
    final incidents = widget.snapshot.mapIncidents;
    MapIncident? active;
    for (final incident in incidents) {
      if (incident.id == _selected) active = incident;
    }
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1.05,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFE7EEF6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.line),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(painter: _ZonePainter()),
                    ),
                    for (final sector in _sectors)
                      _pin(
                        constraints: constraints,
                        x: sector.$3,
                        y: sector.$4,
                        color: AppColors.navy,
                        label: sector.$1,
                        onTap: () {},
                      ),
                    for (final incident in incidents)
                      _pin(
                        constraints: constraints,
                        x: incident.x,
                        y: incident.y,
                        color: incident.critical ? AppColors.red : AppColors.orange,
                        label: incident.kind,
                        onTap: () => setState(() => _selected = incident.id),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Wrap(
          spacing: 12,
          children: [
            _Legend(color: AppColors.navy, label: 'Sector'),
            _Legend(color: AppColors.orange, label: 'Aviso'),
            _Legend(color: AppColors.red, label: 'Crítico'),
          ],
        ),
        const SizedBox(height: 12),
        if (active != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(active.title, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.navyDeep)),
                Text('${active.sector} · ${active.circuit}'),
                Text(active.status, style: const TextStyle(color: AppColors.orangeDark, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(active.detail),
              ],
            ),
          )
        else
          const Text('Toca un aviso naranja o rojo para ver el detalle.', style: TextStyle(color: AppColors.muted)),
        const SizedBox(height: 8),
        const Text('Zona sur esquematizada para la presentación.', style: TextStyle(fontSize: 12, color: AppColors.muted)),
      ],
    );
  }

  Widget _pin({
    required BoxConstraints constraints,
    required double x,
    required double y,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return Positioned(
      left: constraints.maxWidth * x - 8,
      top: constraints.maxHeight * y - 8,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(width: 16, height: 16, decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2))),
            Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.navyDeep)),
          ],
        ),
      ),
    );
  }
}

class _ZonePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFD5E2F2);
    final path = Path()
      ..moveTo(size.width * 0.18, size.height * 0.22)
      ..quadraticBezierTo(size.width * 0.55, size.height * 0.08, size.width * 0.82, size.height * 0.28)
      ..quadraticBezierTo(size.width * 0.9, size.height * 0.55, size.width * 0.48, size.height * 0.78)
      ..quadraticBezierTo(size.width * 0.2, size.height * 0.9, size.width * 0.12, size.height * 0.62)
      ..close();
    canvas.drawPath(path, paint);
    final coast = Paint()
      ..color = AppColors.navy.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(path, coast);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
