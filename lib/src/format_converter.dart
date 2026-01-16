/// Base class for all converters.
abstract class SportsDataConverter<Input, Output> {
  Future<Output> convert(Input input);
}
