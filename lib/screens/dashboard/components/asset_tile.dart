import 'package:agq_app/content/content_image.dart';
import 'package:flutter/material.dart';
import 'package:agq_app/database/models/assets_model.dart';
import 'package:agq_app/screens/utils/utilities.dart';

// ignore: constant_identifier_names
enum FundName { AGQ, AK1 }

// ignore: must_be_immutable
class AssetTile extends StatelessWidget {
  final Asset asset;
  final FundName fund;
  final String? companyName;

  const AssetTile({
    super.key,
    required this.asset,
    required this.fund,
    this.companyName,
  });

  @override
  Widget build(BuildContext context) {

    // String sectionName = getSectionName(fieldName, companyName: companyName);
    // title = sectionName;
    Widget fundIcon = getFundIcon(fund);

    return ListTile(
      leading: fundIcon,
      title: Text(
        asset.displayTitle,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          fontFamily: 'Titillium Web',
        ),
      ),
      trailing: Text(
        currencyFormat(asset.amount),
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          fontFamily: 'Titillium Web',
        ),
      ),
    );
  }

  Widget getFundIcon(FundName fund) {
    switch (fund) {
      case FundName.AGQ:
        return const AppContentImage('assets/icons/agq_logo.svg');
      case FundName.AK1:
        return const AppContentImage('assets/icons/ak1_logo.svg');
      default:
        return const Icon(Icons.account_balance, color: Colors.white);
    }
  }
}
