import '../../core/mock/demo_clock.dart';
import '../../core/mock/mock_seed.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/entities.dart';
import '../models/snapshot_codec.dart';
import 'local_store.dart';

class MockDatabase {
  MockDatabase(this._store);

  final LocalStore _store;
  DemoSnapshot? _current;
  Future<DemoSnapshot>? _loading;

  DemoSnapshot get current => _current!;

  Future<DemoSnapshot> load() {
    if (_current != null) return Future.value(_current!);
    return _loading ??= _read();
  }

  Future<DemoSnapshot> _read() async {
    final raw = await _store.read();
    if (raw != null) {
      try {
        _current = normalize(SnapshotCodec.decode(raw));
        return _current!;
      } catch (_) {
        await _store.clear();
      }
    }
    _current = normalize(MockSeed.build(DemoScenario.normal));
    await _store.write(SnapshotCodec.encode(_current!));
    return _current!;
  }

  Future<DemoSnapshot> commit(DemoSnapshot next) async {
    _current = normalize(next).copyWith(lastUpdated: DemoClock.now);
    await _store.write(SnapshotCodec.encode(_current!));
    return _current!;
  }

  DemoSnapshot normalize(DemoSnapshot snapshot) {
    final invoices = [
      for (final invoice in snapshot.invoices)
        if (invoice.status == InvoiceStatus.paid)
          invoice
        else
          invoice.copyWith(
            status: isPastDue(invoice.dueDate, DemoClock.now) ? InvoiceStatus.overdue : InvoiceStatus.pending,
          ),
    ];
    return snapshot.copyWith(invoices: invoices);
  }
}
