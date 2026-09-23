import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/providers.dart';
import '../../../core/utils/media_url.dart';
import '../../../core/widgets/api_alert.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../models/instructor_model.dart';

class InstructorDirectoryScreen extends ConsumerStatefulWidget {
  const InstructorDirectoryScreen({super.key});

  @override
  ConsumerState<InstructorDirectoryScreen> createState() => _InstructorDirectoryScreenState();
}

class _InstructorDirectoryScreenState extends ConsumerState<InstructorDirectoryScreen> {
  List<InstructorModel> _instructors = [];
  String _searchQuery = '';
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInstructors();
  }

  Future<void> _loadInstructors() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final list = await ref.read(instructorRepositoryProvider).getAllInstructors();
      if (mounted) {
        setState(() {
          _instructors = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final filtered = _instructors.where((i) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      return i.fullName.toLowerCase().contains(query) ||
          (i.expertise != null && i.expertise!.toLowerCase().contains(query)) ||
          (i.biography != null && i.biography!.toLowerCase().contains(query));
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Instructors Directory')),
      body: RefreshIndicator(
        onRefresh: _loadInstructors,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Search by name, expertise, or bio...',
                  prefixIcon: Icon(Icons.search, size: 20),
                  isDense: true,
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
              const SizedBox(height: 12),
              ApiAlert(error: _error, onRetry: _loadInstructors),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filtered.isEmpty
                        ? const EmptyState(
                            title: 'No instructors found',
                            description: 'Try another search query.',
                          )
                        : ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final inst = filtered[index];
                              final photo = mediaUrl(inst.profilePhotoUrl);

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 28,
                                            backgroundColor: theme.colorScheme.primary,
                                            backgroundImage: photo.isNotEmpty
                                                ? (kIsWeb ? NetworkImage(photo) as ImageProvider : CachedNetworkImageProvider(photo))
                                                : null,
                                            onBackgroundImageError: photo.isNotEmpty
                                                ? (exception, stackTrace) {}
                                                : null,
                                            child: photo.isEmpty
                                                ? Text(
                                                    inst.fullName.isNotEmpty ? inst.fullName[0].toUpperCase() : 'I',
                                                    style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
                                                  )
                                                : null,
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  inst.fullName,
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    const Icon(Icons.star, color: Colors.amber, size: 16),
                                                    const SizedBox(width: 3),
                                                    Text(inst.averageRating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                                    const SizedBox(width: 12),
                                                    const Icon(Icons.menu_book, size: 16, color: Colors.grey),
                                                    const SizedBox(width: 4),
                                                    Text('${inst.totalCourses ?? 0} courses', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (inst.email != null && inst.email!.isNotEmpty)
                                            IconButton(
                                              icon: const Icon(Icons.email_outlined),
                                              tooltip: 'Email instructor',
                                              onPressed: () async {
                                                final uri = Uri.parse('mailto:${inst.email}');
                                                if (await canLaunchUrl(uri)) {
                                                  await launchUrl(uri);
                                                }
                                              },
                                            ),
                                        ],
                                      ),
                                      if (inst.biography != null && inst.biography!.isNotEmpty) ...[
                                        const SizedBox(height: 12),
                                        Text(
                                          inst.biography!,
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 13, height: 1.4),
                                        ),
                                      ],
                                      if (inst.expertiseList.isNotEmpty) ...[
                                        const SizedBox(height: 10),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 4,
                                          children: inst.expertiseList.map((tag) {
                                            return Chip(
                                              label: Text(tag, style: const TextStyle(fontSize: 11)),
                                              padding: EdgeInsets.zero,
                                              visualDensity: VisualDensity.compact,
                                            );
                                          }).toList(),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
