import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';

/// 加载中组件
class LoadingWidget extends StatelessWidget {
  final String? message;

  const LoadingWidget({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.lovePink),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Shimmer 加载效果
class ShimmerLoading extends StatelessWidget {
  final Widget child;

  const ShimmerLoading({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.6,
      child: child,
    );
  }
}

/// 错误组件
class CustomErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const CustomErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('重试'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 空状态组件
class EmptyWidget extends StatelessWidget {
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? icon;

  const EmptyWidget({
    super.key,
    this.message,
    this.actionLabel,
    this.onAction,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon ?? Icons.inbox_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              message ?? '暂无内容',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 通用状态组件
class AsyncStateWidget<T> extends StatelessWidget {
  final AsyncValue<T> data;
  final Widget Function(T data) builder;
  final String? loadingMessage;
  final String? emptyMessage;
  final String? emptyActionLabel;
  final VoidCallback? emptyOnAction;
  final IconData? emptyIcon;
  final VoidCallback? onErrorRetry;

  const AsyncStateWidget({
    super.key,
    required this.data,
    required this.builder,
    this.loadingMessage,
    this.emptyMessage,
    this.emptyActionLabel,
    this.emptyOnAction,
    this.emptyIcon,
    this.onErrorRetry,
  });

  @override
  Widget build(BuildContext context) {
    return data.when(
      loading: () => LoadingWidget(message: loadingMessage),
      error: (error, stack) => CustomErrorWidget(
        message: error.toString(),
        onRetry: onErrorRetry,
      ),
      data: (data) {
        if (data is List && data.isEmpty) {
          return EmptyWidget(
            message: emptyMessage,
            actionLabel: emptyActionLabel,
            onAction: emptyOnAction,
            icon: emptyIcon,
          );
        }
        return builder(data);
      },
    );
  }
}
