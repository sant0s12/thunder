import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thunder/shared/image_preview.dart';
import 'package:thunder/utils/font_size.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import 'package:thunder/account/bloc/account_bloc.dart';
import 'package:thunder/community/pages/community_page.dart';
import 'package:thunder/core/auth/bloc/auth_bloc.dart';
import 'package:thunder/shared/webview.dart';
import 'package:thunder/thunder/bloc/thunder_bloc.dart';
import 'package:thunder/utils/instance.dart';

class CommonMarkdownBody extends StatefulWidget {
  final String body;
  final bool isSelectableText;

  const CommonMarkdownBody({super.key, required this.body, String? data, this.isSelectableText = false});

  @override
  State<CommonMarkdownBody> createState() => _CommonMarkdownBodyState();
}

class _CommonMarkdownBodyState extends State<CommonMarkdownBody> {
  double titleFontSizeScaleFactor = 1.0;
  double contentFontSizeScaleFactor = 1.0;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _initPreferences());
    super.initState();
  }

  @override
  void didUpdateWidget(covariant CommonMarkdownBody oldWidget) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _initPreferences());
    super.didUpdateWidget(oldWidget);
  }

  Future<void> _initPreferences() async {
    Map<String, double> textScaleFactor = await getTextScaleFactor();

    setState(() {
      titleFontSizeScaleFactor = textScaleFactor['titleFontSizeScaleFactor'] ?? 1.0;
      contentFontSizeScaleFactor = textScaleFactor['contentFontSizeScaleFactor'] ?? 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    bool openInExternalBrowser = false;

    try {
      openInExternalBrowser = context.read<ThunderBloc>().state.preferences?.getBool('setting_links_open_in_external_browser') ?? false;
    } catch (e) {}

    return MarkdownBody(
      data: widget.body,
      imageBuilder: (uri, title, alt) {
        return ImagePreview(
          url: uri.toString(),
          width: MediaQuery.of(context).size.width - 24,
          isExpandable: true,
          showFullHeightImages: true,
        );
      },
      selectable: widget.isSelectableText,
      onTapLink: (text, url, title) {
        String? communityName = checkLemmyInstanceUrl(text);
        if (communityName != null) {
          // Push navigation
          AccountBloc accountBloc = context.read<AccountBloc>();
          AuthBloc authBloc = context.read<AuthBloc>();
          ThunderBloc thunderBloc = context.read<ThunderBloc>();

          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => MultiBlocProvider(
                providers: [
                  BlocProvider.value(value: accountBloc),
                  BlocProvider.value(value: authBloc),
                  BlocProvider.value(value: thunderBloc),
                ],
                child: CommunityPage(communityName: communityName),
              ),
            ),
          );
        } else if (url != null) {
          if (openInExternalBrowser == true) {
            launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
          } else {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => WebView(url: url)));
          }
        }
      },
      styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
        textScaleFactor: contentFontSizeScaleFactor,
        p: theme.textTheme.bodyMedium,
        blockquoteDecoration: const BoxDecoration(
          color: Colors.transparent,
          border: Border(left: BorderSide(color: Colors.grey, width: 4)),
        ),
      ),
    );
  }
}
