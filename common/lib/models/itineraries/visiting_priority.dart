enum VisitingPriority {
  low,
  mid,
  high,
  notApplicable,
  school,

  // TODO Implement this on app side
  // extension VisitingPriorityStyled on VisitingPriority {
  // MaterialColor get color {
  //   switch (this) {
  //     case (VisitingPriority.low):
  //       return Colors.green;
  //     case (VisitingPriority.mid):
  //       return Colors.orange;
  //     case (VisitingPriority.high):
  //       return Colors.red;
  //     case (VisitingPriority.school):
  //       return Colors.purple;
  //     case (VisitingPriority.notApplicable):
  //       return Colors.grey;
  //   }
  // }

  // IconData get icon {
  //   switch (this) {
  //     case (VisitingPriority.low):
  //       return Icons.looks_3;
  //     case (VisitingPriority.mid):
  //       return Icons.looks_two;
  //     case (VisitingPriority.high):
  //       return Icons.looks_one;
  //     case (VisitingPriority.school):
  //       return Icons.school;
  //     case (VisitingPriority.notApplicable):
  //       return Icons.cancel;
  //   }
  // }

  // VisitingPriority get next => VisitingPriority.values[(index - 1) % 3];
}
