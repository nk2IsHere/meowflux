import 'package:dataclass_beta/dataclass_beta.dart';

part 'root_state.g.dart';

@dataClass
class FirstRootState extends _$FirstRootState {
  final int value;

  FirstRootState({
    this.value
  });
}


@dataClass
class SecondRootState extends _$SecondRootState {
  final int value;

  SecondRootState({
    this.value
  });
}