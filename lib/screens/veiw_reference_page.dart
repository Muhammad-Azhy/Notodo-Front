// import 'package:flutter/material.dart';
// import './new_reference_page.dart';

// class ViewReferencePage extends StatelessWidget {
//   final Map<String, dynamic> reference;
//   final Function(Map<String, dynamic>) onUpdate;
//   final Function() onDelete;
//   final int? initialProblemId;

//   const ViewReferencePage({
//     super.key,
//     required this.reference,
//     required this.onUpdate,
//     required this.onDelete,
//     this.initialProblemId,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(reference['title'] ?? "View Reference"),
//         backgroundColor: Theme.of(context).scaffoldBackgroundColor,
//         foregroundColor: Theme.of(context).textTheme.bodyMedium!.color,
//         elevation: 0,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.delete),
//             onPressed: () {
//               onDelete();
//               Navigator.pop(context);
//             },
//           ),
//         ],
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             Expanded(
//               child: reference['type'] == 'image'
//                   ? Image.asset(reference['content'] ?? '')
//                   : SingleChildScrollView(
//                       child: Text(reference['content'] ?? ''),
//                     ),
//             ),
//             const SizedBox(height: 16),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton.icon(
//                 icon: const Icon(Icons.edit),
//                 label: const Text("Edit Reference"),
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (_) => NewReferencePage(
//                         initialType: reference['type'] ?? 'text',
//                         // initialTitle: reference['title'],

//                         // initialContent: reference['content'],
//                         onCreate: (updatedRef) {
//                           onUpdate(updatedRef);
//                           Navigator.pop(context);
//                           Navigator.pop(context);
//                         },
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
