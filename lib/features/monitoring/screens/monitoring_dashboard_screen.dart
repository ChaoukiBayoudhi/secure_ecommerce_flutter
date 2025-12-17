/// Monitoring Dashboard Screen
/// 
/// Admin-only screen for system health monitoring and AI agent actions.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/http_client_service.dart';

class MonitoringDashboardScreen extends ConsumerStatefulWidget {
  const MonitoringDashboardScreen({super.key});

  @override
  ConsumerState<MonitoringDashboardScreen> createState() =>
      _MonitoringDashboardScreenState();
}

class _MonitoringDashboardScreenState
    extends ConsumerState<MonitoringDashboardScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _dashboardData;
  String? _errorMessage;
  final _dio = HttpClientService().dio;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _dio.get('/monitoring/dashboard/');
      setState(() {
        _dashboardData = response.data as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🤖 AI Monitoring Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboard,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading dashboard',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(_errorMessage!),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _loadDashboard,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadDashboard,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_dashboardData?['current_health'] != null)
                            _buildHealthCard(
                              _dashboardData!['current_health'] as Map<String, dynamic>,
                            ),
                          const SizedBox(height: 16),
                          if (_dashboardData?['recent_alerts'] != null)
                            _buildAlertsCard(
                              _dashboardData!['recent_alerts'] as List<dynamic>,
                            ),
                          const SizedBox(height: 16),
                          if (_dashboardData?['recent_actions'] != null)
                            _buildActionsCard(
                              _dashboardData!['recent_actions'] as List<dynamic>,
                            ),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildHealthCard(Map<String, dynamic> health) {
    final status = health['overall_status'] as String? ?? 'unknown';
    final cpuUsage = health['cpu_usage'] as num? ?? 0;
    final memoryUsage = health['memory_usage'] as num? ?? 0;
    final avgResponseTime = health['avg_response_time'] as num? ?? 0;

    Color statusColor;
    switch (status.toLowerCase()) {
      case 'healthy':
        statusColor = Colors.green;
        break;
      case 'warning':
        statusColor = Colors.orange;
        break;
      case 'critical':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'System Health',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetric('CPU', '$cpuUsage%', cpuUsage > 80 ? Colors.red : Colors.green),
                _buildMetric('Memory', '$memoryUsage%', memoryUsage > 80 ? Colors.red : Colors.green),
                _buildMetric('Response', '${avgResponseTime}ms', avgResponseTime > 500 ? Colors.orange : Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildAlertsCard(List<dynamic> alerts) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Alerts',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (alerts.isEmpty)
              const Text('No recent alerts')
            else
              ...alerts.take(5).map((alert) {
                final alertData = alert as Map<String, dynamic>;
                final severity = alertData['severity'] as String? ?? 'info';
                final title = alertData['title'] as String? ?? 'Alert';
                final message = alertData['message'] as String? ?? '';
                
                Color severityColor;
                switch (severity.toLowerCase()) {
                  case 'critical':
                    severityColor = Colors.red;
                    break;
                  case 'warning':
                    severityColor = Colors.orange;
                    break;
                  default:
                    severityColor = Colors.blue;
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(color: severityColor, width: 4),
                    ),
                    color: severityColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (message.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          message,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                        ),
                      ],
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard(List<dynamic> actions) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent AI Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (actions.isEmpty)
              const Text('No recent AI actions')
            else
              ...actions.take(5).map((action) {
                final actionData = action as Map<String, dynamic>;
                final actionType = actionData['action_type'] as String? ?? 'Unknown';
                final description = actionData['description'] as String? ?? '';

                return ListTile(
                  leading: const Icon(Icons.smart_toy),
                  title: Text(actionType),
                  subtitle: description.isNotEmpty ? Text(description) : null,
                  dense: true,
                );
              }),
          ],
        ),
      ),
    );
  }
}

