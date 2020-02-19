import 'package:meowflux/core/action.dart';
import 'package:meowflux/extensions/stream_extensions.dart';
import 'package:meowflux/worker/worker.dart';
import 'package:meowflux/worker/worker_context.dart';

typedef _Watch<A extends Action, S> = Future<Null> Function(Stream<A> actionStream, WorkerContext<S> context);

class Watcher<A extends Action, S> {
  _Watch<Action, S> watch;
}

Watcher<A, S> watcher<A extends Action, S>(
  Worker<A, S> worker,
  Stream<Action> Function(Stream<Action> actionStream, WorkerContext<S> context) select 
) => Watcher<A, S>()
  ..watch = (Stream<Action> actionStream, WorkerContext<S> context) async {
    await applyWorker<A, S>(
      select(actionStream, context), 
      context, 
      worker
    );
  };