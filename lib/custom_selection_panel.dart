// ignore_for_file: use_super_parameters

library custom_expansion_panel;

import 'package:flutter/material.dart';

const double _kPanelHeaderCollapsedHeight = 48.0;
const EdgeInsets _kPanelHeaderExpandedDefaultPadding = EdgeInsets.symmetric(vertical: 60.0 - _kPanelHeaderCollapsedHeight,);
const double _kPanelDividerHeight = 12.0;
const Color _kPanelDividerColor = Colors.grey;
const double _kPanelCardElevation = 4.0;
const Duration _kThemeAnimationDuration = Duration(milliseconds: 250,);

class _SaltedKey<S, V> extends LocalKey {
  final S salt;
  final V value;

  const _SaltedKey(this.salt, this.value);

  @override bool operator ==(Object other) {
    if (other.runtimeType != runtimeType)return false;

    return other is _SaltedKey<S, V> && other.salt == salt && other.value == value;
  }

  @override int get hashCode => Object.hash(runtimeType, salt, value);

  @override String toString() {
    final String saltString = S == String ? "<'$salt'>" : '<$salt>';
    final String valueString = V == String ? "<'$value'>" : '<$value>';
    return '[$saltString $valueString]';
  }
}

typedef SelectionPanelCallback = void Function(int, bool,);
typedef SelectionPanelContentBuilder = Widget Function(BuildContext, bool,);

class SelectionPanelListItem {
  final bool isSelected;
  final bool canBeSelected;

  final SelectionPanelContentBuilder headerWidgetBuilder;
  final SelectionPanelContentBuilder bodyWidgetBuilder;

  SelectionPanelListItem({
    this.isSelected = false,
    this.canBeSelected = true,
    required this.headerWidgetBuilder,
    required this.bodyWidgetBuilder,
  });
}

class SelectionPanelRadio extends SelectionPanelListItem {
  final Object value;

  SelectionPanelRadio({
    required this.value,
    required SelectionPanelContentBuilder headerWidgetBuilder,
    required SelectionPanelContentBuilder bodyWidgetBuilder,
    required bool canBeSelected,
    required bool isSelected,
  })
  : super(
    canBeSelected: canBeSelected, isSelected: isSelected, headerWidgetBuilder: headerWidgetBuilder, bodyWidgetBuilder: bodyWidgetBuilder,
  );
}

class SelectionPanelList extends StatefulWidget {
  const SelectionPanelList({
    Key? key,
    this.children = const <SelectionPanelListItem>[],
    this.expansionCallback,
    this.animationDuration = _kThemeAnimationDuration,
    this.expandedHeaderPadding = _kPanelHeaderExpandedDefaultPadding,
    this.dividerHeight = _kPanelDividerHeight,
    this.dividerColor = _kPanelDividerColor,
    this.elevation = _kPanelCardElevation,
    this.selectionTitle,
    this.selectionIconColor = Colors.black,
    this.selectionIconSize = const Size(24.0, 24.0,),
    this.decoration = const BoxDecoration(color: Colors.white,),
  }) : allowOnlyOnePanelOpen = false, initialOpenPanelValue = null, super(key: key,);

  const SelectionPanelList.radio({
    Key? key,
    this.initialOpenPanelValue,
    this.children = const <SelectionPanelListItem>[],
    this.expansionCallback,
    this.animationDuration = _kThemeAnimationDuration,
    this.expandedHeaderPadding = _kPanelHeaderExpandedDefaultPadding,
    this.dividerHeight = _kPanelDividerHeight,
    this.dividerColor = _kPanelDividerColor,
    this.elevation = _kPanelCardElevation,
    this.selectionTitle,
    this.selectionIconColor = Colors.black,
    this.selectionIconSize = const Size(24.0, 24.0,),
    this.decoration = const BoxDecoration(color: Colors.white,),
  }) : allowOnlyOnePanelOpen = true, super(key: key,);


  final bool allowOnlyOnePanelOpen;
  final Object? initialOpenPanelValue;
  final List<SelectionPanelListItem> children;
  final SelectionPanelCallback? expansionCallback;

  final double elevation;
  final double dividerHeight;
  final Color dividerColor;
  final EdgeInsets expandedHeaderPadding;
  final Duration animationDuration;

  final Text? selectionTitle;
  final Color selectionIconColor;
  final Size selectionIconSize;
  final Decoration decoration;

  @override State<StatefulWidget> createState() => _SelectionPanelListState();
}

class _SelectionPanelListState extends State<SelectionPanelList> {
  SelectionPanelRadio? _currentOpenPanel;

  @override void initState() {
    super.initState();
    if (widget.allowOnlyOnePanelOpen) {
      assert(_allIdentifiersUnique(), 'items-non-unique-identifier-values',);
      if (widget.initialOpenPanelValue != null) {
        _currentOpenPanel = searchPanelByValue(widget.children.cast<SelectionPanelRadio>(), widget.initialOpenPanelValue,);
      }
    }
  }

  @override void didUpdateWidget(SelectionPanelList oldWidget,) {
    super.didUpdateWidget(oldWidget,);
    if (widget.allowOnlyOnePanelOpen) {
      assert(_allIdentifiersUnique(), 'items-non-unique-identifier-values',);
      if (!oldWidget.allowOnlyOnePanelOpen) {
        _currentOpenPanel = searchPanelByValue(widget.children.cast<SelectionPanelRadio>(), widget.initialOpenPanelValue,);
      }
    } else {
      _currentOpenPanel = null;
    }
  }

  bool _allIdentifiersUnique() {
    final Map<Object, bool> identifierMap = <Object, bool>{};
    for (final SelectionPanelRadio child in widget.children.cast<SelectionPanelRadio>()) {
      identifierMap[child.value] = true;
    }
    return identifierMap.length == widget.children.length;
  }

  bool _isChildExpanded(int index,) {
    if (widget.allowOnlyOnePanelOpen) {
      final SelectionPanelRadio radioWidget = widget.children[index] as SelectionPanelRadio;
      return _currentOpenPanel?.value == radioWidget.value;
    }
    return widget.children[index].isSelected;
  }

  void _handlePressed(int index, bool isSelected,) {
    if (widget.expansionCallback != null) widget.expansionCallback!(index, isSelected,);

    if (widget.allowOnlyOnePanelOpen) {
      final SelectionPanelRadio pressedChild = widget.children[index] as SelectionPanelRadio;
      for (int childIndex = 0; childIndex < widget.children.length; childIndex += 1) {
        final SelectionPanelRadio child = widget.children[childIndex] as SelectionPanelRadio;
        if (widget.expansionCallback != null && childIndex != index && child.value == _currentOpenPanel?.value) {
          if (widget.expansionCallback != null) widget.expansionCallback!(childIndex, false);
        }
      }
      setState(() => _currentOpenPanel = isSelected ? null : pressedChild,);
    }
  }

  SelectionPanelRadio? searchPanelByValue(List<SelectionPanelRadio> panels, Object? value,)  {
    for (final SelectionPanelRadio panel in panels) {
      if (panel.value == value) return panel;
    }
    return null;
  }

  @override Widget build(BuildContext context,) {
    assert(kElevationToShadow.containsKey(widget.elevation,), "invalid-elevation-value",);

    final List<MergeableMaterialItem> items = <MergeableMaterialItem>[];

    for (int index = 0; index < widget.children.length; index += 1) {
      if (index != 0) {
        items.add(MaterialGap(key: _SaltedKey<BuildContext, int>(context, index * 2 - 1), size: widget.dividerHeight,));
      }

      final SelectionPanelListItem panelItem = widget.children[index];
      final Widget headerWidget = panelItem.headerWidgetBuilder(context, _isChildExpanded(index),);
      final Widget bodyWidget = _isChildExpanded(index) ? panelItem.bodyWidgetBuilder(context, true,) : const SizedBox.shrink();

      final MaterialLocalizations localizations = MaterialLocalizations.of(context);
      final Widget expandIconContainer = Theme(
        data: Theme.of(context).copyWith(),
        child: Semantics(
          label: panelItem.canBeSelected ? null : (_isChildExpanded(index) ? localizations.expandedIconTapHint : localizations.collapsedIconTapHint),
          container: !panelItem.canBeSelected,
          checked: panelItem.canBeSelected,
          child: Container(
            constraints: BoxConstraints.tight(widget.selectionIconSize,),
            margin: const EdgeInsetsDirectional.only(start: 8.0,),
            child: Transform.scale(
              scale: 1.5,
              child: Checkbox(
                value: _isChildExpanded(index,),
                checkColor: Colors.white,
                fillColor: MaterialStateProperty.resolveWith((states) {
                  if (states.contains(MaterialState.selected)) return widget.selectionIconColor;
                  return Colors.transparent;
                }),
                shape: RoundedRectangleBorder(
                  side: BorderSide.none,
                  borderRadius: BorderRadius.circular(4.0,),
                ),
                side: BorderSide(color: widget.selectionIconColor, width: 2.0,),
                onChanged: (bool? isSelected,) {
                  return _handlePressed(index, (panelItem.canBeSelected ? (isSelected ?? false) : false),);
                },
              ),
            ),
          ),
        ),
      );

      final Widget header = MergeSemantics(
        child: InkWell(
          onTap: panelItem.canBeSelected ? () => _handlePressed(index, _isChildExpanded(index,),) : null,
          child: Row(
            children: <Widget>[
              expandIconContainer,
              Expanded(
                child: AnimatedContainer(
                  duration: widget.animationDuration,
                  curve: Curves.fastOutSlowIn,
                  margin: _isChildExpanded(index) ? EdgeInsets.zero : EdgeInsets.zero,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: _kPanelHeaderCollapsedHeight),
                    child: headerWidget,
                  ),
                ),
              ),
              if(widget.selectionTitle != null) ...[
                const SizedBox(width: 4.0,),
                widget.selectionTitle!,
              ],
            ],
          ),
        ),
      );

      final Widget body = AnimatedCrossFade(
        firstChild: SizedBox.fromSize(size: Size.zero,),
        secondChild: bodyWidget,
        firstCurve: const Interval(0.0, 0.6, curve: Curves.fastOutSlowIn,),
        secondCurve: const Interval(0.4, 1.0, curve: Curves.fastOutSlowIn,),
        sizeCurve: Curves.fastOutSlowIn,
        crossFadeState: _isChildExpanded(index) ? CrossFadeState.showSecond : CrossFadeState.showFirst,
        duration: widget.animationDuration,
      );

      items.add(
        MaterialSlice(
          key: _SaltedKey<BuildContext, int>(context, index * 2),
          child: DecoratedBox(
            decoration: widget.decoration,
            child: ClipRRect(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: <Widget>[
                  header,
                  body,
                ],
              ),
            ),
          ),
        ),
      );
    }

    return MergeableMaterial(
      hasDividers: false,
      mainAxis: Axis.vertical,
      dividerColor: widget.dividerColor,
      elevation: widget.elevation,
      children: items,
    );
  }
}
