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

typedef ExpansionPanelCallback = void Function(int, bool,);
typedef ExpansionPanelContentBuilder = Widget Function(BuildContext, bool,);

class ExpansionPanelListItem {
  bool isExpanded = false;

  final bool canBeExpanded;
  final ExpansionPanelContentBuilder headerWidgetBuilder;
  final ExpansionPanelContentBuilder bodyWidgetBuilder;

  ExpansionPanelListItem({
    this.canBeExpanded = true,
    required this.headerWidgetBuilder,
    required this.bodyWidgetBuilder,
  });
}

class ExpansionPanelListRadioItem extends ExpansionPanelListItem {
  final Object value;

  ExpansionPanelListRadioItem({
    required this.value,
    required bool canBeExpanded,
    required ExpansionPanelContentBuilder headerWidgetBuilder,
    required ExpansionPanelContentBuilder bodyWidgetBuilder,
  }) : super(
    canBeExpanded: canBeExpanded, headerWidgetBuilder: headerWidgetBuilder, bodyWidgetBuilder: bodyWidgetBuilder,
  );
}

class ExpansionPanelList extends StatefulWidget {
  const ExpansionPanelList({
    Key? key,
    this.children = const <ExpansionPanelListItem>[],
    this.expansionCallback,
    this.animationDuration = _kThemeAnimationDuration,
    this.expandedHeaderPadding = _kPanelHeaderExpandedDefaultPadding,
    this.dividerHeight = _kPanelDividerHeight,
    this.dividerColor = _kPanelDividerColor,
    this.elevation = _kPanelCardElevation,
    this.expansionTitle,
    this.expansionIconColor = Colors.black,
    this.expansionIconSize = const Size(24.0, 24.0,),
    this.decoration = const BoxDecoration(color: Colors.white,),
  }) : allowOnlyOnePanelOpen = false, initialOpenPanelValue = null, super(key: key,);

  const ExpansionPanelList.radio({
    Key? key,
    this.initialOpenPanelValue,
    this.children = const <ExpansionPanelListItem>[],
    this.expansionCallback,
    this.animationDuration = _kThemeAnimationDuration,
    this.expandedHeaderPadding = _kPanelHeaderExpandedDefaultPadding,
    this.dividerHeight = _kPanelDividerHeight,
    this.dividerColor = _kPanelDividerColor,
    this.elevation = _kPanelCardElevation,
    this.expansionTitle,
    this.expansionIconColor = Colors.black,
    this.expansionIconSize = const Size(24.0, 24.0,),
    this.decoration = const BoxDecoration(color: Colors.white,),
  }) : allowOnlyOnePanelOpen = true, super(key: key,);

  final bool allowOnlyOnePanelOpen;
  final Object? initialOpenPanelValue;
  final List<ExpansionPanelListItem> children;
  final ExpansionPanelCallback? expansionCallback;

  final double elevation;
  final double dividerHeight;
  final Color dividerColor;
  final EdgeInsets expandedHeaderPadding;
  final Duration animationDuration;

  final Decoration decoration;
  final Color expansionIconColor;
  final Size expansionIconSize;
  final Text? expansionTitle;

  @override State<StatefulWidget> createState() => _ExpansionPanelListState();
}

class _ExpansionPanelListState extends State<ExpansionPanelList> {
  ExpansionPanelListRadioItem? _currentOpenPanel;

  @override void initState() {
    super.initState();
    if (widget.allowOnlyOnePanelOpen) {
      assert(_allIdentifiersUnique(), 'items-non-unique-identifier-values');
      if (widget.initialOpenPanelValue != null) {
        _currentOpenPanel = searchPanelByValue(widget.children.cast<ExpansionPanelListRadioItem>(), widget.initialOpenPanelValue,);
      }
    }
  }

  @override void didUpdateWidget(ExpansionPanelList oldWidget,) {
    super.didUpdateWidget(oldWidget,);
    if (widget.allowOnlyOnePanelOpen) {
      assert(_allIdentifiersUnique(), 'items-non-unique-identifier-values');
      if (!oldWidget.allowOnlyOnePanelOpen) {
        _currentOpenPanel = searchPanelByValue(widget.children.cast<ExpansionPanelListRadioItem>(), widget.initialOpenPanelValue,);
      }
    } else {
      _currentOpenPanel = null;
    }
  }

  bool _allIdentifiersUnique() {
    final Map<Object, bool> identifierMap = <Object, bool>{};
    for (final ExpansionPanelListRadioItem child in widget.children.cast<ExpansionPanelListRadioItem>()) {
      identifierMap[child.value] = true;
    }
    return identifierMap.length == widget.children.length;
  }

  bool _isChildExpanded(int index,) {
    if (widget.allowOnlyOnePanelOpen) {
      final child = widget.children[index] as ExpansionPanelListRadioItem;
      return _currentOpenPanel?.value == child.value;
    }
    return widget.children[index].isExpanded;
  }

  void _handlePressed(int index, bool isExpanded,) {
    final pressedChild = widget.children[index] as ExpansionPanelListRadioItem;
    if (widget.allowOnlyOnePanelOpen) {
      for (int childIndex = 0; childIndex < widget.children.length; childIndex += 1) {
        final child = widget.children[childIndex] as ExpansionPanelListRadioItem;
        if (childIndex != index) {
          child.isExpanded = false;
          if (widget.expansionCallback != null) widget.expansionCallback!(childIndex, false,);
        }
      }
    }

    setState(() {
      pressedChild.isExpanded = isExpanded;
      if (widget.expansionCallback != null) widget.expansionCallback!(index, isExpanded,);
      _currentOpenPanel = isExpanded ? pressedChild : null;
    });
  }

  ExpansionPanelListRadioItem? searchPanelByValue(List<ExpansionPanelListRadioItem> panels, Object? value,)  {
    for (final ExpansionPanelListRadioItem panel in panels) {
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

      final ExpansionPanelListItem panelItem = widget.children[index];
      final Widget headerWidget = panelItem.headerWidgetBuilder(context, _isChildExpanded(index,),);
      final Widget bodyWidget = panelItem.bodyWidgetBuilder(context, _isChildExpanded(index,),);

      final MaterialLocalizations localizations = MaterialLocalizations.of(context);
      final Widget expandIconContainer = Theme(
        data: Theme.of(context).copyWith(),
        child: Semantics(
          label: panelItem.canBeExpanded ? null : (_isChildExpanded(index) ? localizations.expandedIconTapHint : localizations.collapsedIconTapHint),
          container: !panelItem.canBeExpanded,
          button: panelItem.canBeExpanded,
          child: Container(
            constraints: BoxConstraints.tight(widget.expansionIconSize,),
            margin: const EdgeInsetsDirectional.only(start: 0.0,),
            child: Transform.scale(
              scale: 1.5,
              child: ExpandIcon(
                isExpanded: _isChildExpanded(index,),
                padding: EdgeInsets.zero,
                onPressed: (bool isExpanded,) {
                  return _handlePressed(index, panelItem.canBeExpanded ? !isExpanded : false,);
                },
                color: widget.expansionIconColor,
                disabledColor: widget.expansionIconColor,
                expandedColor: widget.expansionIconColor,
              ),
            ),
          ),
        ),
      );

      final Widget header = MergeSemantics(
        child: InkWell(
          onTap: panelItem.canBeExpanded ? () => _handlePressed(index, _isChildExpanded(index,),) : null,
          child: Row(
            children: <Widget>[
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
              if(widget.expansionTitle != null) widget.expansionTitle!,
              expandIconContainer,
            ],
          ),
        ),
      );

      final Widget body = AnimatedCrossFade(
        firstChild: const SizedBox.shrink(),
        secondChild: bodyWidget,
        sizeCurve: Curves.linear,
        firstCurve: const Interval(0.0, 1.0, curve: Curves.linearToEaseOut,),
        secondCurve: const Interval(0.0, 1.0, curve: Curves.linearToEaseOut,),
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
      dividerColor: widget.dividerColor,
      elevation: widget.elevation,
      children: items,
    );
  }
}

