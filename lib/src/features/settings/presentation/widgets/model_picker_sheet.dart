import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../chat/application/chat_providers.dart';
import '../../../chat/domain/ai_model.dart';

/// Searchable bottom sheet listing the models available for the current
/// provider. For OpenRouter this is fetched live and filtered to free models.
class ModelPickerSheet extends ConsumerStatefulWidget {
  const ModelPickerSheet({super.key, required this.selectedId});

  final String selectedId;

  /// Opens the sheet and resolves to the chosen model id, or `null`.
  static Future<String?> show(BuildContext context, String selectedId) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => ModelPickerSheet(selectedId: selectedId),
    );
  }

  @override
  ConsumerState<ModelPickerSheet> createState() => _ModelPickerSheetState();
}

class _ModelPickerSheetState extends ConsumerState<ModelPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final models = ref.watch(availableModelsProvider);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              autofocus: false,
              onChanged: (value) =>
                  setState(() => _query = value.trim().toLowerCase()),
              decoration: const InputDecoration(
                hintText: 'Search free models…',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          Expanded(
            child: models.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('$error')),
              data: (items) => _ModelList(
                models: _filter(items),
                selectedId: widget.selectedId,
                scrollController: scrollController,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<AiModel> _filter(List<AiModel> models) {
    if (_query.isEmpty) return models;
    return models
        .where(
          (model) =>
              model.name.toLowerCase().contains(_query) ||
              model.id.toLowerCase().contains(_query),
        )
        .toList(growable: false);
  }
}

class _ModelList extends StatelessWidget {
  const _ModelList({
    required this.models,
    required this.selectedId,
    required this.scrollController,
  });

  final List<AiModel> models;
  final String selectedId;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    if (models.isEmpty) {
      return const Center(child: Text('No models match that search.'));
    }

    return ListView.builder(
      controller: scrollController,
      itemCount: models.length,
      itemBuilder: (context, index) {
        final model = models[index];
        final isSelected = model.id == selectedId;

        return ListTile(
          selected: isSelected,
          title: Text(model.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            [
              model.id,
              if (model.contextLabel != null) model.contextLabel!,
            ].join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: isSelected ? const Icon(Icons.check_rounded) : null,
          onTap: () => Navigator.of(context).pop(model.id),
        );
      },
    );
  }
}
