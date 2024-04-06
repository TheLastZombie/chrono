import 'package:clock_app/common/types/list_controller.dart';
import 'package:clock_app/common/types/list_filter.dart';
import 'package:clock_app/common/types/list_item.dart';
import 'package:clock_app/common/utils/reorderable_list_decorator.dart';
import 'package:clock_app/common/widgets/list/list_filter_chip.dart';
import 'package:clock_app/common/widgets/list/list_item_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:great_list_view/great_list_view.dart';

typedef ItemCardBuilder = Widget Function(
  BuildContext context,
  int index,
  AnimatedWidgetBuilderData data,
);

class CustomListView<Item extends ListItem> extends StatefulWidget {
  const CustomListView({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.listController,
    this.onTapItem,
    this.onReorderItem,
    this.onDeleteItem,
    this.onAddItem,
    this.placeholderText = '',
    // Called whenever an item is added, deleted or reordered
    this.onModifyList,
    this.isReorderable = true,
    this.isDeleteEnabled = true,
    this.isDuplicateEnabled = true,
    this.shouldInsertOnTop = true,
    this.listFilters = const [],
    this.customActions = const [],
  });

  final List<Item> items;
  final Widget Function(Item item) itemBuilder;
  final void Function(Item item, int index)? onTapItem;
  final void Function(Item item)? onReorderItem;
  final void Function(Item item)? onDeleteItem;
  final void Function(Item item)? onAddItem;
  // Called whenever an item is added, deleted or reordered
  final void Function()? onModifyList;
  final String placeholderText;
  final ListController<Item> listController;
  final bool isReorderable;
  final bool isDeleteEnabled;
  final bool isDuplicateEnabled;
  final bool shouldInsertOnTop;
  final List<ListFilterItem<Item>> listFilters;
  final List<ListFilterCustomAction<Item>> customActions;

  @override
  State<CustomListView> createState() => _CustomListViewState<Item>();
}

class _CustomListViewState<Item extends ListItem>
    extends State<CustomListView<Item>> {
  double _itemCardHeight = 0;
  late int lastListLength = widget.items.length;
  final _scrollController = ScrollController();
  final _controller = AnimatedListController();
  // late ListFilter<Item> _selectedFilter = widget.listFilters.isEmpty
  //     ? ListFilter("Default", (item) => true)
  //     : widget.listFilters[0];

  @override
  void initState() {
    super.initState();
    widget.listController.setChangeItems(_changeItems);
    widget.listController.setAddItem(_handleAddItem);
    widget.listController.setDeleteItem(_handleDeleteItem);
    widget.listController.setGetItemIndex(_getItemIndex);
    widget.listController.setDuplicateItem(_handleDuplicateItem);
    widget.listController.setReloadItems(_reloadItems);
    widget.listController.setClearItems(_handleClear);
  }

  void _reloadItems(List<Item> items) {
    setState(() {
      widget.items.clear();
      widget.items.addAll(items);
    });
// TODO: MAN THIS SUCKS, WHY YOU GOTTA DO THIS
    _controller.notifyRemovedRange(
        0, widget.items.length - 1, _getChangeListBuilder());
    _controller.notifyInsertedRange(0, widget.items.length);
  }

  int _getItemIndex(Item item) =>
      widget.items.indexWhere((element) => element.id == item.id);

  void _updateItemHeight() {
    if (_itemCardHeight == 0) {
      _itemCardHeight = _controller.computeItemBox(0)?.height ?? 0;
    }
  }

  void _changeItems(ItemChangerCallback<Item> callback, bool callOnModifyList) {
    setState(() {
      callback(widget.items);
    });
    _notifyChangeList();

    if (callOnModifyList) widget.onModifyList?.call();
  }

  void _notifyChangeList() {
    // print("============================= ${widget.items.length}");
    _controller.notifyChangedRange(
      0,
      widget.items.length,
      _getChangeListBuilder(),
    );
  }

  ItemCardBuilder _getChangeWidgetBuilder(Item item) {
    _updateItemHeight();
    return (context, index, data) => data.measuring
        ? SizedBox(height: _itemCardHeight)
        : ListItemCard<Item>(
            key: ValueKey(item),
            onTap: () {},
            onDelete: () {},
            onDuplicate: () {},
            child: widget.itemBuilder(item),
          );
  }

  ItemCardBuilder _getChangeListBuilder() => (context, index, data) =>
      _getChangeWidgetBuilder(widget.items[index])(context, index, data);

  bool _handleReorderItems(int oldIndex, int newIndex, Object? slot) {
    if (newIndex >= widget.items.length) return false;
    widget.onReorderItem?.call(widget.items[oldIndex]);
    widget.items.insert(newIndex, widget.items.removeAt(oldIndex));
    widget.onModifyList?.call();

    return true;
  }

  void _handleDeleteItem(Item deletedItem) {
    widget.onDeleteItem?.call(deletedItem);
    int index = _getItemIndex(deletedItem);
    setState(() {
      widget.items.removeAt(index);
    });

    _controller.notifyRemovedRange(
      index,
      1,
      _getChangeWidgetBuilder(deletedItem),
    );
    widget.onModifyList?.call();
    lastListLength = widget.items.length;
  }

  void _handleClear() {
    int listLength = widget.items.length;

    setState(() {
      widget.items.clear();
    });

    _controller.notifyRemovedRange(
      0,
      listLength,
      _getChangeListBuilder(),
    );
    widget.onModifyList?.call();
    lastListLength = widget.items.length;
  }

  void _handleAddItem(Item item, {int index = -1}) {
    if (index == -1) {
      index = widget.shouldInsertOnTop ? 0 : widget.items.length;
    }
    setState(() => widget.items.insert(index, item));
    widget.onAddItem?.call(item);
    _controller.notifyInsertedRange(index, 1);
    _scrollToIndex(index);
    Future.delayed(const Duration(milliseconds: 250), () {
      _scrollToIndex(index);
    });
    _updateItemHeight();
    widget.onModifyList?.call();
  }

  void _handleDuplicateItem(Item item) {
    _handleAddItem(item.copy(), index: _getItemIndex(item) + 1);
  }

  void _scrollToIndex(int index) {
    // if (_scrollController.offset == 0) {
    //   _scrollController.jumpTo(1);
    // }
    if (_itemCardHeight == 0 && index != 0) return;
    _scrollController.animateTo(index * _itemCardHeight,
        duration: const Duration(milliseconds: 250), curve: Curves.easeIn);
  }

  _getItemBuilder() {
    return (BuildContext context, Item item, data) {
      for (var filter in widget.listFilters) {
        // print("${filter.displayName} ${filter.filterFunction}");
        if (!filter.filterFunction(item)) {
          return Container();
        }
      }
      return data.measuring
          ? SizedBox(height: _itemCardHeight)
          : ListItemCard<Item>(
              key: ValueKey(item),
              onTap: () {
                return widget.onTapItem?.call(item, _getItemIndex(item));
              },
              onDelete:
                  widget.isDeleteEnabled ? () => _handleDeleteItem(item) : null,
              onDuplicate: () => _handleDuplicateItem(item),
              isDeleteEnabled: item.isDeletable && widget.isDeleteEnabled,
              isDuplicateEnabled: widget.isDuplicateEnabled,
              child: widget.itemBuilder(item),
            );
    };
  }

  void onFilterChange() {
    setState(() {
      _notifyChangeList();
    });
  }

  Widget getListFilterChip(ListFilterItem<Item> item) {
    if (item.runtimeType == ListFilter<Item>) {
      return ListFilterChip<Item>(
        listFilter: item as ListFilter<Item>,
        onChange: onFilterChange,
      );
    } else if (item.runtimeType == ListFilterSelect<Item>) {
      return ListFilterSelectChip<Item>(
        listFilter: item as ListFilterSelect<Item>,
        onChange: onFilterChange,
      );
    } else if (item.runtimeType == ListFilterMultiSelect<Item>) {
      return ListFilterMultiSelectChip<Item>(
        listFilter: item as ListFilterMultiSelect<Item>,
        onChange: onFilterChange,
      );
    } else if (item.runtimeType == DynamicListFilterSelect<Item>) {
      return ListFilterSelectChip<Item>(
        listFilter: item as DynamicListFilterSelect<Item>,
        onChange: onFilterChange,
      );
    } else if (item.runtimeType == DynamicListFilterMultiSelect<Item>) {
      return ListFilterMultiSelectChip<Item>(
        listFilter: item as DynamicListFilterMultiSelect<Item>,
        onChange: onFilterChange,
      );
    } else {
      return const Text("Unknown Filter Type");
    }
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    ColorScheme colorScheme = theme.colorScheme;

    List<Widget> getFilterChips() {
      List<Widget> widgets = [];
      int activeFilterCount =
          widget.listFilters.where((filter) => filter.isActive).length;
      if (activeFilterCount > 0) {
        widgets.add(ListFilterActionChip(
          actions: [
            ListFilterAction(
              name: "Clear all filters",
              icon: Icons.clear_rounded,
              action: () {
                for (var filter in widget.listFilters) {
                  filter.reset();
                }
                onFilterChange();
              },
            ),
            ...widget.customActions.map((action) => ListFilterAction(
                  name: action.name,
                  icon: action.icon,
                  action: () {
                    _changeItems((items) {
                      for (var item in items) {
                        action.action(item);
                      }
                    }, true);
                  },
                )),
            ListFilterAction(
              name: "Delete all filtered items",
              icon: Icons.delete_rounded,
              color: colorScheme.error,
              action: () async {
                Navigator.pop(context);
                final result = await showDialog<bool>(
                  context: context,
                  builder: (buildContext) {
                    return AlertDialog(
                      actionsPadding:
                          const EdgeInsets.only(bottom: 6, right: 10),
                      content: Text(
                          "Do you want to delete all filtered ${widget.placeholderText}?"),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context, false);
                          },
                          child: Text("No",
                              style: TextStyle(color: colorScheme.primary)),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context, true);
                          },
                          child: Text("Yes",
                              style: TextStyle(color: colorScheme.error)),
                        ),
                      ],
                    );
                  },
                );

                print("------------- $result");

                if (result == null || result == false) return;

                final toRemove = widget.items.where((item) => widget.listFilters
                    .every((filter) => filter.filterFunction(item)));
                while (toRemove.isNotEmpty) {
                  _handleDeleteItem(toRemove.first);
                }
              },
            )
          ],
          activeFilterCount: activeFilterCount,
        ));
      }
      widgets.addAll(
          widget.listFilters.map((filter) => getListFilterChip(filter)));
      return widgets;
    }

    timeDilation = 0.75;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: getFilterChips(),
              ),
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Stack(children: [
            widget.items.isEmpty
                ? SizedBox(
                    height: double.infinity,
                    width: double.infinity,
                    child: Center(
                      child: Text(
                        widget.placeholderText,
                        style:
                            Theme.of(context).textTheme.displaySmall?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onBackground
                                      .withOpacity(0.6),
                                ),
                      ),
                    ),
                  )
                : Container(),
            SlidableAutoCloseBehavior(
              child: AutomaticAnimatedListView<Item>(
                list: widget.items,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                comparator: AnimatedListDiffListComparator<Item>(
                  sameItem: (a, b) => a.id == b.id,
                  sameContent: (a, b) => a.id == b.id,
                ),
                itemBuilder: _getItemBuilder(),
                // animator: DefaultAnimatedListAnimator,
                listController: _controller,
                scrollController: _scrollController,
                addLongPressReorderable: widget.isReorderable,
                reorderModel: widget.isReorderable
                    ? AnimatedListReorderModel(
                        onReorderStart: (index, dx, dy) => true,
                        onReorderFeedback: (int index, int dropIndex,
                                double offset, double dx, double dy) =>
                            null,
                        onReorderMove: (int index, int dropIndex) => true,
                        onReorderComplete: _handleReorderItems,
                      )
                    : null,
                reorderDecorationBuilder:
                    widget.isReorderable ? reorderableListDecorator : null,
                footer: const SizedBox(height: 64 + 80),
                // cacheExtent: double.infinity,
              ),
            ),
          ]),
        ),
      ],
    );
  }
}
