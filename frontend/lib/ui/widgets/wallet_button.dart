import 'package:flutter/material.dart';
import 'package:google_wallet/google_wallet.dart';
import 'package:url_launcher/url_launcher.dart';

class WalletButton extends StatefulWidget {
  const WalletButton({super.key, required this.jwt});
  final String? jwt;

  @override
  State<WalletButton> createState() => _WalletButtonState();
}

class _WalletButtonState extends State<WalletButton> {
  bool? _available;
  final _gw = GoogleWallet();

  @override
  void initState() {
    super.initState();
    _gw.isAvailable().then((v) => setState(() => _available = v));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.jwt == null) return const SizedBox();
    return ElevatedButton(
      onPressed: () async {
        try {
          if (_available == true) {
            await _gw.savePassesJwt(widget.jwt!);
          } else {
            final url = Uri.parse('https://pay.google.com/gp/v/save/${widget.jwt}');
            await launchUrl(url, mode: LaunchMode.externalApplication);
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Wallet error $e')),
          );
        }
      },
      child: const Text('Add to Wallet'),
    );
  }
}
