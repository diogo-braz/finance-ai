import 'package:finance_ai/ui/core/themes/colors.dart';
import 'package:finance_ai/ui/new_expense/view_models/new_expense_viewmodel.dart';
import 'package:flutter/material.dart';

class NewExpenseValue extends StatelessWidget {
  const NewExpenseValue({
    super.key,
    required this.viewModel,
  });

  final NewExpenseViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            "How much?",
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: AppColors.light20,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${viewModel.expenseAmountDetailsRecognized?.total ?? 0}',
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  color: Colors.white,
                ),
          ),
        ],
      ),
    );
  }
}
