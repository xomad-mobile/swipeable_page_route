import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:meta/meta.dart';

import 'app_bar.dart';

// Most of this file is a copy from material/app_bar.dart (with slight
// modifications due to stricter linting rules). I didn't find a better way
// because we need to change the AppBar widget created in _SliverAppBarDelegate
// and _FloatingAppBar is private…

class _FloatingAppBar extends StatefulWidget {
  const _FloatingAppBar({Key key, this.child}) : super(key: key);

  final Widget child;

  @override
  _FloatingAppBarState createState() => _FloatingAppBarState();
}

// A wrapper for the widget created by _SliverAppBarDelegate that starts and
// stops the floating app bar's snap-into-view or snap-out-of-view animation.
class _FloatingAppBarState extends State<_FloatingAppBar> {
  ScrollPosition _position;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_position != null) {
      _position.isScrollingNotifier.removeListener(_isScrollingListener);
    }
    _position = Scrollable.of(context)?.position;
    if (_position != null) {
      _position.isScrollingNotifier.addListener(_isScrollingListener);
    }
  }

  @override
  void dispose() {
    if (_position != null) {
      _position.isScrollingNotifier.removeListener(_isScrollingListener);
    }
    super.dispose();
  }

  RenderSliverFloatingPersistentHeader _headerRenderer() {
    return context
        .findAncestorRenderObjectOfType<RenderSliverFloatingPersistentHeader>();
  }

  void _isScrollingListener() {
    if (_position == null) {
      return;
    }

    // When a scroll stops, then maybe snap the appbar into view.
    // Similarly, when a scroll starts, then maybe stop the snap animation.
    final header = _headerRenderer();
    if (_position.isScrollingNotifier.value) {
      header?.maybeStopSnapAnimation(_position.userScrollDirection);
    } else {
      header?.maybeStartSnapAnimation(_position.userScrollDirection);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate({
    @required this.heroTag,
    @required this.leading,
    @required this.automaticallyImplyLeading,
    @required this.title,
    @required this.actions,
    @required this.flexibleSpace,
    @required this.bottom,
    @required this.elevation,
    @required this.forceElevated,
    @required this.backgroundColor,
    @required this.brightness,
    @required this.iconTheme,
    @required this.actionsIconTheme,
    @required this.textTheme,
    @required this.primary,
    @required this.centerTitle,
    @required this.titleSpacing,
    @required this.expandedHeight,
    @required this.collapsedHeight,
    @required this.topPadding,
    @required this.floating,
    @required this.pinned,
    @required this.snapConfiguration,
    @required this.stretchConfiguration,
    @required this.shape,
  })  : assert(heroTag != null),
        assert(primary || topPadding == 0.0),
        _bottomHeight = bottom?.preferredSize?.height ?? 0.0;

  final Object heroTag;
  final Widget leading;
  final bool automaticallyImplyLeading;
  final Widget title;
  final List<Widget> actions;
  final Widget flexibleSpace;
  final PreferredSizeWidget bottom;
  final double elevation;
  final bool forceElevated;
  final Color backgroundColor;
  final Brightness brightness;
  final IconThemeData iconTheme;
  final IconThemeData actionsIconTheme;
  final TextTheme textTheme;
  final bool primary;
  final bool centerTitle;
  final double titleSpacing;
  final double expandedHeight;
  final double collapsedHeight;
  final double topPadding;
  final bool floating;
  final bool pinned;
  final ShapeBorder shape;

  final double _bottomHeight;

  @override
  double get minExtent =>
      collapsedHeight ?? (topPadding + kToolbarHeight + _bottomHeight);

  @override
  double get maxExtent => math.max(
      topPadding + (expandedHeight ?? kToolbarHeight + _bottomHeight),
      minExtent);

  @override
  final FloatingHeaderSnapConfiguration snapConfiguration;

  @override
  final OverScrollHeaderStretchConfiguration stretchConfiguration;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final visibleMainHeight = maxExtent - shrinkOffset - topPadding;

    // Truth table for `toolbarOpacity`:
    // pinned | floating | bottom != null || opacity
    // ----------------------------------------------
    //    0   |    0     |        0       ||  fade
    //    0   |    0     |        1       ||  fade
    //    0   |    1     |        0       ||  fade
    //    0   |    1     |        1       ||  fade
    //    1   |    0     |        0       ||  1.0
    //    1   |    0     |        1       ||  1.0
    //    1   |    1     |        0       ||  1.0
    //    1   |    1     |        1       ||  fade
    final double toolbarOpacity = !pinned || (floating && bottom != null)
        ? ((visibleMainHeight - _bottomHeight) / kToolbarHeight).clamp(0.0, 1.0)
        : 1.0;

    final appBar = FlexibleSpaceBar.createSettings(
      minExtent: minExtent,
      maxExtent: maxExtent,
      currentExtent: math.max(minExtent, maxExtent - shrinkOffset),
      toolbarOpacity: toolbarOpacity,
      child: MorphingAppBar(
        heroTag: heroTag,
        leading: leading,
        automaticallyImplyLeading: automaticallyImplyLeading,
        title: title,
        actions: actions,
        flexibleSpace: (title == null && flexibleSpace != null)
            ? Semantics(header: true, child: flexibleSpace)
            : flexibleSpace,
        bottom: bottom,
        elevation: forceElevated ||
                overlapsContent ||
                (pinned && shrinkOffset > maxExtent - minExtent)
            ? elevation ?? 4.0
            : 0.0,
        backgroundColor: backgroundColor,
        brightness: brightness,
        iconTheme: iconTheme,
        actionsIconTheme: actionsIconTheme,
        textTheme: textTheme,
        primary: primary,
        centerTitle: centerTitle,
        titleSpacing: titleSpacing,
        shape: shape,
        toolbarOpacity: toolbarOpacity,
        bottomOpacity:
            pinned ? 1.0 : (visibleMainHeight / _bottomHeight).clamp(0.0, 1.0),
      ),
    );
    return floating ? _FloatingAppBar(child: appBar) : appBar;
  }

  @override
  bool shouldRebuild(covariant _SliverAppBarDelegate oldDelegate) {
    return heroTag != oldDelegate.heroTag ||
        leading != oldDelegate.leading ||
        automaticallyImplyLeading != oldDelegate.automaticallyImplyLeading ||
        title != oldDelegate.title ||
        actions != oldDelegate.actions ||
        flexibleSpace != oldDelegate.flexibleSpace ||
        bottom != oldDelegate.bottom ||
        _bottomHeight != oldDelegate._bottomHeight ||
        elevation != oldDelegate.elevation ||
        backgroundColor != oldDelegate.backgroundColor ||
        brightness != oldDelegate.brightness ||
        iconTheme != oldDelegate.iconTheme ||
        actionsIconTheme != oldDelegate.actionsIconTheme ||
        textTheme != oldDelegate.textTheme ||
        primary != oldDelegate.primary ||
        centerTitle != oldDelegate.centerTitle ||
        titleSpacing != oldDelegate.titleSpacing ||
        expandedHeight != oldDelegate.expandedHeight ||
        topPadding != oldDelegate.topPadding ||
        pinned != oldDelegate.pinned ||
        floating != oldDelegate.floating ||
        snapConfiguration != oldDelegate.snapConfiguration ||
        stretchConfiguration != oldDelegate.stretchConfiguration;
  }

  @override
  String toString() {
    return '${describeIdentity(this)}(topPadding: ${topPadding.toStringAsFixed(1)}, bottomHeight: ${_bottomHeight.toStringAsFixed(1)}, ...)';
  }
}

/// An adapted version of [SliverAppBar] that morphs while navigating.
class MorphingSliverAppBar extends StatefulWidget {
  /// Creates a material design app bar that can be placed in a [CustomScrollView].
  ///
  /// The arguments [forceElevated], [primary], [floating], [pinned], [snap]
  /// and [automaticallyImplyLeading] must not be null.
  const MorphingSliverAppBar({
    Key key,
    this.heroTag = 'MorphingAppBar',
    this.leading,
    this.automaticallyImplyLeading = true,
    this.title,
    this.actions,
    this.flexibleSpace,
    this.bottom,
    this.elevation,
    this.forceElevated = false,
    this.backgroundColor,
    this.brightness,
    this.iconTheme,
    this.actionsIconTheme,
    this.textTheme,
    this.primary = true,
    this.centerTitle,
    this.titleSpacing = NavigationToolbar.kMiddleSpacing,
    this.expandedHeight,
    this.floating = false,
    this.pinned = false,
    this.snap = false,
    this.stretch = false,
    this.stretchTriggerOffset = 100.0,
    this.onStretchTrigger,
    this.shape,
  })  : assert(heroTag != null),
        assert(automaticallyImplyLeading != null),
        assert(forceElevated != null),
        assert(primary != null),
        assert(titleSpacing != null),
        assert(floating != null),
        assert(pinned != null),
        assert(snap != null),
        assert(stretch != null),
        assert(floating || !snap,
            'The "snap" argument only makes sense for floating app bars.'),
        assert(stretchTriggerOffset > 0.0),
        super(key: key);

  /// Tag used for the internally created [Hero] widget.
  final Object heroTag;

  /// See [SliverAppBar.leading].
  final Widget leading;

  /// See [SliverAppBar.automaticallyImplyLeading].
  final bool automaticallyImplyLeading;

  /// See [SliverAppBar.title].
  final Widget title;

  /// See [SliverAppBar.actions].
  final List<Widget> actions;

  /// See [SliverAppBar.flexibleSpace].
  final Widget flexibleSpace;

  /// See [SliverAppBar.bottom].
  final PreferredSizeWidget bottom;

  /// See [SliverAppBar.elevation].
  final double elevation;

  /// See [SliverAppBar.forceElevated].
  final bool forceElevated;

  /// See [SliverAppBar.backgroundColor].
  final Color backgroundColor;

  /// See [SliverAppBar.brightness].
  final Brightness brightness;

  /// See [SliverAppBar.iconTheme].
  final IconThemeData iconTheme;

  /// See [SliverAppBar.actionsIconTheme].
  final IconThemeData actionsIconTheme;

  /// See [SliverAppBar.textTheme].
  final TextTheme textTheme;

  /// See [SliverAppBar.primary].
  final bool primary;

  /// See [SliverAppBar.centerTitle].
  final bool centerTitle;

  /// See [SliverAppBar.titleSpacing].
  final double titleSpacing;

  /// See [SliverAppBar.expandedHeight].
  final double expandedHeight;

  /// See [SliverAppBar.floating].
  final bool floating;

  /// See [SliverAppBar.pinned].
  final bool pinned;

  /// See [SliverAppBar.shape].
  final ShapeBorder shape;

  /// See [SliverAppBar.snap].
  final bool snap;

  /// See [SliverAppBar.stretch].
  final bool stretch;

  /// See [SliverAppBar.stretchTriggerOffset].
  final double stretchTriggerOffset;

  /// See [SliverAppBar.onStretchTrigger].
  final AsyncCallback onStretchTrigger;

  @override
  _SliverAppBarState createState() => _SliverAppBarState();
}

// This class is only Stateful because it owns the TickerProvider used
// by the floating appbar snap animation (via FloatingHeaderSnapConfiguration).
class _SliverAppBarState extends State<MorphingSliverAppBar>
    with TickerProviderStateMixin {
  FloatingHeaderSnapConfiguration _snapConfiguration;
  OverScrollHeaderStretchConfiguration _stretchConfiguration;

  void _updateSnapConfiguration() {
    if (widget.snap && widget.floating) {
      _snapConfiguration = FloatingHeaderSnapConfiguration(
        vsync: this,
        curve: Curves.easeOut,
        duration: const Duration(milliseconds: 200),
      );
    } else {
      _snapConfiguration = null;
    }
  }

  void _updateStretchConfiguration() {
    if (widget.stretch) {
      _stretchConfiguration = OverScrollHeaderStretchConfiguration(
        stretchTriggerOffset: widget.stretchTriggerOffset,
        onStretchTrigger: widget.onStretchTrigger,
      );
    } else {
      _stretchConfiguration = null;
    }
  }

  @override
  void initState() {
    super.initState();
    _updateSnapConfiguration();
    _updateStretchConfiguration();
  }

  @override
  void didUpdateWidget(MorphingSliverAppBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.snap != oldWidget.snap ||
        widget.floating != oldWidget.floating) {
      _updateSnapConfiguration();
    }
    if (widget.stretch != oldWidget.stretch) {
      _updateStretchConfiguration();
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(!widget.primary || debugCheckHasMediaQuery(context));
    final topPadding =
        widget.primary ? MediaQuery.of(context).padding.top : 0.0;
    final collapsedHeight =
        (widget.pinned && widget.floating && widget.bottom != null)
            ? widget.bottom.preferredSize.height + topPadding
            : null;

    return MediaQuery.removePadding(
      context: context,
      removeBottom: true,
      child: SliverPersistentHeader(
        floating: widget.floating,
        pinned: widget.pinned,
        delegate: _SliverAppBarDelegate(
          heroTag: widget.heroTag,
          leading: widget.leading,
          automaticallyImplyLeading: widget.automaticallyImplyLeading,
          title: widget.title,
          actions: widget.actions,
          flexibleSpace: widget.flexibleSpace,
          bottom: widget.bottom,
          elevation: widget.elevation,
          forceElevated: widget.forceElevated,
          backgroundColor: widget.backgroundColor,
          brightness: widget.brightness,
          iconTheme: widget.iconTheme,
          actionsIconTheme: widget.actionsIconTheme,
          textTheme: widget.textTheme,
          primary: widget.primary,
          centerTitle: widget.centerTitle,
          titleSpacing: widget.titleSpacing,
          expandedHeight: widget.expandedHeight,
          collapsedHeight: collapsedHeight,
          topPadding: topPadding,
          floating: widget.floating,
          pinned: widget.pinned,
          shape: widget.shape,
          snapConfiguration: _snapConfiguration,
          stretchConfiguration: _stretchConfiguration,
        ),
      ),
    );
  }
}