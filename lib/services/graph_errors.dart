import '../domain/types.dart';

/// A write that `GraphService` refused because it would break a rule.
/// [message] is written for the user and can go straight into a snackbar.
///
/// `sealed` means every subclass is in this file, so a `switch` over one is
/// checked for completeness (like a discriminated union).
sealed class GraphRuleException implements Exception {
  const GraphRuleException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// Bad or missing input: an empty label, an unknown id, a self-link.
final class InvalidInput extends GraphRuleException {
  const InvalidInput(super.message);
}

/// The hierarchical edge (or edge-type change) would form a loop.
final class CycleBlocked extends GraphRuleException {
  const CycleBlocked(super.message);
}

/// The types chosen for a node conflict with each other.
final class TypeConflictBlocked extends GraphRuleException {
  const TypeConflictBlocked(super.message, this.conflicts);

  final List<TypeConflict> conflicts;
}

/// Editing a type would break nodes that already use it.
final class TypeEditBlocked extends GraphRuleException {
  const TypeEditBlocked(super.message, {this.affectedNodeIds = const []});

  /// Nodes whose types would start conflicting.
  final List<String> affectedNodeIds;
}
