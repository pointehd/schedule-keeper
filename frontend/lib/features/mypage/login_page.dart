import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/providers/plan_provider.dart';
import '../../shared/theme/app_colors.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F3F8),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 28, color: Color(0xFF333333)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
        child: Column(
          children: [
            _buildAvatar(),
            const SizedBox(height: 28),
            _buildHeader(),
            const SizedBox(height: 32),
            _buildBenefitsCard(),
            const SizedBox(height: 32),
            _buildLoginButtons(context),
            const SizedBox(height: 28),
            _buildGuestLink(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: const Color(0xFFE8E9F8),
        borderRadius: BorderRadius.circular(28),
      ),
      child: const Icon(
        Icons.person_outline_rounded,
        size: 52,
        color: kPrimary,
      ),
    );
  }

  Widget _buildHeader() {
    return const Text(
      '로그인이 필요해요',
      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
    );
  }

  Widget _buildBenefitsCard() {
    const items = [
      ('🔒', '계획 · 기록 안전 저장'),
      ('📱', '모든 기기 실시간 동기화'),
      ('📊', '장기 통계 · 달성 히스토리'),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: items.map((item) {
          final isLast = item == items.last;
          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
            child: Row(
              children: [
                Text(item.$1, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 14),
                Text(
                  item.$2,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF333333)),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLoginButtons(BuildContext context) {
    return Column(
      children: [
        _SocialButton(
          label: 'Apple로 계속하기',
          backgroundColor: const Color(0xFF000000),
          foregroundColor: Colors.white,
          icon: const _AppleIcon(),
          onTap: () => _handleLogin(context, 'Apple'),
        ),
        const SizedBox(height: 12),
        _SocialButton(
          label: 'Google로 계속하기',
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1A1A1A),
          border: Border.all(color: const Color(0xFFDDDDDD)),
          icon: const _GoogleIcon(),
          onTap: () => _handleLogin(context, 'Google'),
        ),
        const SizedBox(height: 12),
        _SocialButton(
          label: '카카오로 계속하기',
          backgroundColor: const Color(0xFFFEE500),
          foregroundColor: const Color(0xFF1A1A1A),
          icon: const _KakaoIcon(),
          onTap: () => _handleLogin(context, 'Kakao'),
        ),
        const SizedBox(height: 12),
        _SocialButton(
          label: '네이버로 계속하기',
          backgroundColor: const Color(0xFF03C75A),
          foregroundColor: Colors.white,
          icon: const _NaverIcon(),
          onTap: () => _handleLogin(context, 'Naver'),
        ),
      ],
    );
  }

  Widget _buildGuestLink(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: const Text.rich(
        TextSpan(
          text: '로그인 없이 ',
          style: TextStyle(fontSize: 14, color: Color(0xFFAAAAAA)),
          children: [
            TextSpan(
              text: '게스트로 계속하기 →',
              style: TextStyle(
                color: Color(0xFF555555),
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
                decorationColor: Color(0xFF555555),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleLogin(BuildContext context, String provider) {
    final notifier = context.read<PlanNotifier>();
    notifier.login(provider);
    Navigator.of(context).pop();
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final BoxBorder? border;
  final Widget icon;
  final VoidCallback onTap;

  const _SocialButton({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    this.border,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: backgroundColor,
          border: border,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 22, height: 22, child: icon),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: foregroundColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppleIcon extends StatelessWidget {
  const _AppleIcon();

  @override
  Widget build(BuildContext context) {
    return const Icon(Icons.apple, color: Colors.white, size: 22);
  }
}

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(22, 22), painter: _GoogleLogoPainter());
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    final bgPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(cx, cy), r, bgPaint);

    const segments = [
      (0.0, 90.0, Color(0xFF4285F4)),
      (90.0, 180.0, Color(0xFF34A853)),
      (180.0, 270.0, Color(0xFFFBBC05)),
      (270.0, 360.0, Color(0xFFEA4335)),
    ];

    for (final seg in segments) {
      final paint = Paint()
        ..color = seg.$3
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.18
        ..strokeCap = StrokeCap.butt;
      final startRad = seg.$1 * 3.14159265 / 180;
      final sweepRad = (seg.$2 - seg.$1) * 3.14159265 / 180;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.72),
        startRad,
        sweepRad,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _KakaoIcon extends StatelessWidget {
  const _KakaoIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: const BoxDecoration(
        color: Color(0xFFFEE500),
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Icon(Icons.chat_bubble, size: 13, color: Color(0xFF3C1E1E)),
      ),
    );
  }
}

class _NaverIcon extends StatelessWidget {
  const _NaverIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: const BoxDecoration(
        color: Color(0xFF03C75A),
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Text(
          'N',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
