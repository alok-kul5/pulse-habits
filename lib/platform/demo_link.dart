/// Links into the web demo, so a README or a recruiter can jump straight to a
/// screen: `?tab=stats`, `?habit=read`, `?sheet=new`, `?splash=0`.
class DemoLink {
  const DemoLink({this.tab = 0, this.habit, this.sheet, this.splash = true});

  final int tab;
  final String? habit;
  final String? sheet;
  final bool splash;

  static const tabs = ['today', 'stats', 'train', 'you'];

  static DemoLink parse(Uri uri) {
    final q = uri.queryParameters;
    final tab = tabs.indexOf(q['tab'] ?? '');
    return DemoLink(
      tab: tab < 0 ? 0 : tab,
      habit: q['habit'],
      sheet: switch (q['sheet']) {
        'new' || 'log' => q['sheet'],
        _ => null,
      },
      splash: q['splash'] != '0',
    );
  }
}
