// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:provider/provider.dart';
// import '../../../models/resourceApp/task_model.dart';
// import '../../../services/resourceApp/firestore_service.dart';
// import '../../../services/auth_service.dart';
// import '../../../widgets/custom_button.dart';
// import '../../../widgets/custom_text_field.dart';

// class TaskDetailScreenResource extends StatefulWidget {
//   final TaskModel task;

//   const TaskDetailScreenResource({super.key, required this.task});

//   @override
//   State<TaskDetailScreenResource> createState() =>
//       _TaskDetailScreenResourceState();
// }

// class _TaskDetailScreenResourceState extends State<TaskDetailScreenResource> {
//   final FirestoreServiceResource _firestoreService = FirestoreServiceResource();
//   final _completionNoteController = TextEditingController();
//   bool _isLoading = false;

//   @override
//   void dispose() {
//     _completionNoteController.dispose();
//     super.dispose();
//   }

//   // --- LOGIKA UNTUK MENYELESAIKAN TUGAS ---

//   void _showCompleteDialog() {
//     _completionNoteController.clear();
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Selesaikan Tugas'),
//         content: CustomTextField(
//           labelText: 'Catatan Penyelesaian',
//           hintText: 'Masukkan catatan pekerjaan...',
//           controller: _completionNoteController,
//           maxLines: 3,
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Batal'),
//           ),
//           TextButton(
//             onPressed: _completeTask,
//             child: _isLoading
//                 ? const CircularProgressIndicator(strokeWidth: 2)
//                 : const Text('Selesaikan',
//                     style: TextStyle(color: Colors.green)),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _completeTask() async {
//     if (_completionNoteController.text.trim().isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//             content: Text('Harap berikan catatan penyelesaian'),
//             backgroundColor: Colors.red),
//       );
//       return;
//     }
//     setState(() => _isLoading = true);
//     try {
//       await _firestoreService.updateTaskStatus(
//         widget.task.id,
//         'completed',
//         completionNote: _completionNoteController.text.trim(),
//       );
//       if (mounted) {
//         Navigator.pop(context); // Close dialog
//         Navigator.pop(context); // Kembali ke dashboard
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//               content: Text('Tugas ditandai selesai'),
//               backgroundColor: Colors.green),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         Navigator.pop(context); // Close dialog
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
//         );
//       }
//     } finally {
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Detail Tugas'),
//         backgroundColor: Theme.of(context).primaryColor,
//         foregroundColor: Colors.white,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // --- Status Box ---
//             Container(
//               width: double.infinity,
//               padding: const EdgeInsets.all(20),
//               decoration: BoxDecoration(
//                 color: widget.task.getStatusColor().withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(12),
//                 border: Border.all(color: widget.task.getStatusColor()),
//               ),
//               child: Column(
//                 children: [
//                   Icon(
//                     widget.task.getStatusIcon(),
//                     color: widget.task.getStatusColor(),
//                     size: 48,
//                   ),
//                   const SizedBox(height: 12),
//                   Text(
//                     'Status: ${widget.task.getStatusDisplayName()}',
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                       color: widget.task.getStatusColor(),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 24),

//             // --- Informasi Tugas ---
//             _buildSectionTitle('Informasi Tugas'),
//             const SizedBox(height: 12),
//             _buildInfoCard([
//               _buildInfoRow(Icons.person, 'Pemohon', widget.task.requesterName),
//               if (widget.task.timeRequired != null &&
//                   widget.task.timeRequired!.isNotEmpty)
//                 _buildInfoRow(Icons.calendar_today, 'Waktu Pelaksanaan',
//                     widget.task.timeRequired!),
//               _buildInfoRow(
//                 Icons.access_time,
//                 'Ditugaskan',
//                 DateFormat('EEEE, d MMM yyyy, HH:mm', 'id_ID')
//                     .format(widget.task.assignedAt),
//               ),
//             ]),
//             const SizedBox(height: 24),

//             // --- Deskripsi Kebutuhan ---
//             _buildSectionTitle('Deskripsi Tugas'),
//             const SizedBox(height: 12),
//             Container(
//               width: double.infinity,
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Colors.grey[50],
//                 borderRadius: BorderRadius.circular(8),
//                 border: Border.all(color: Colors.grey[200]!),
//               ),
//               child: Text(
//                 widget.task.description,
//                 style: TextStyle(
//                     fontSize: 16, height: 1.5, color: Colors.grey[800]),
//               ),
//             ),

//             // --- Catatan Penyelesaian (jika sudah selesai) ---
//             if (widget.task.status == 'completed' &&
//                 widget.task.completionNote != null) ...[
//               const SizedBox(height: 24),
//               _buildSectionTitle('Catatan Penyelesaian Anda'),
//               const SizedBox(height: 12),
//               Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Colors.green[50],
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(color: Colors.green[200]!),
//                 ),
//                 child: Text(
//                   widget.task.completionNote!,
//                   style: TextStyle(
//                       fontSize: 16, height: 1.5, color: Colors.green[800]),
//                 ),
//               ),
//             ],

//             const SizedBox(height: 32),

//             // --- Tombol Aksi (jika belum selesai) ---
//             if (widget.task.status == 'inProgress')
//               CustomButton(
//                 text: 'Tandai Selesai',
//                 onPressed: _showCompleteDialog,
//                 backgroundColor: Colors.green,
//                 icon: Icons.check_circle,
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   // --- Helper Widgets ---

//   Widget _buildSectionTitle(String title) {
//     return Text(
//       title,
//       style: TextStyle(
//           fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800]),
//     );
//   }

//   Widget _buildInfoCard(List<Widget> children) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(children: children),
//     );
//   }

//   Widget _buildInfoRow(IconData icon, String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Icon(icon, size: 20, color: Colors.grey[600]),
//           const SizedBox(width: 16),
//           SizedBox(
//             width: 120,
//             child: Text(
//               label,
//               style: TextStyle(
//                   fontWeight: FontWeight.w600, color: Colors.grey[700]),
//             ),
//           ),
//           Expanded(
//             child: Text(
//               value,
//               style: TextStyle(
//                   fontWeight: FontWeight.w500,
//                   fontSize: 15,
//                   color: Colors.grey[900]),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
