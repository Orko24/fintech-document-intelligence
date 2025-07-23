import React from 'react';
import { useQuery } from 'react-query';
import { 
  BarChart, 
  Bar, 
  XAxis, 
  YAxis, 
  CartesianGrid, 
  Tooltip, 
  ResponsiveContainer,
  LineChart,
  Line,
  PieChart,
  Pie,
  Cell
} from 'recharts';
import { 
  FileText, 
  TrendingUp, 
  AlertTriangle, 
  CheckCircle,
  Clock,
  DollarSign,
  Users,
  Activity
} from 'lucide-react';
import { motion } from 'framer-motion';

// Mock data - replace with actual API calls
const mockStats = {
  totalDocuments: 1247,
  processedToday: 89,
  pendingProcessing: 23,
  successRate: 94.2,
  totalTransactions: 5678,
  suspiciousTransactions: 12,
  activeUsers: 156,
  systemHealth: 'Healthy'
};

const mockChartData = [
  { name: 'Jan', documents: 120, transactions: 450 },
  { name: 'Feb', documents: 140, transactions: 520 },
  { name: 'Mar', documents: 180, transactions: 600 },
  { name: 'Apr', documents: 160, transactions: 580 },
  { name: 'May', documents: 200, transactions: 700 },
  { name: 'Jun', documents: 220, transactions: 750 },
];

const mockPieData = [
  { name: 'Invoices', value: 35, color: '#3B82F6' },
  { name: 'Receipts', value: 25, color: '#10B981' },
  { name: 'Contracts', value: 20, color: '#F59E0B' },
  { name: 'Reports', value: 20, color: '#EF4444' },
];

const StatCard: React.FC<{
  title: string;
  value: string | number;
  icon: React.ComponentType<{ className?: string }>;
  trend?: string;
  color: string;
}> = ({ title, value, icon: Icon, trend, color }) => (
  <motion.div
    initial={{ opacity: 0, y: 20 }}
    animate={{ opacity: 1, y: 0 }}
    transition={{ duration: 0.5 }}
    className="bg-white dark:bg-gray-800 rounded-lg shadow-md p-6"
  >
    <div className="flex items-center justify-between">
      <div>
        <p className="text-sm font-medium text-gray-600 dark:text-gray-400">
          {title}
        </p>
        <p className="text-2xl font-bold text-gray-900 dark:text-white">
          {value}
        </p>
        {trend && (
          <p className="text-sm text-green-600 dark:text-green-400">
            {trend}
          </p>
        )}
      </div>
      <div className={`p-3 rounded-full ${color}`}>
        <Icon className="w-6 h-6 text-white" />
      </div>
    </div>
  </motion.div>
);

const Dashboard: React.FC = () => {
  // Mock API queries - replace with actual API calls
  const { data: stats, isLoading: statsLoading } = useQuery('dashboard-stats', 
    () => Promise.resolve(mockStats), 
    { refetchInterval: 30000 }
  );

  const { data: chartData, isLoading: chartLoading } = useQuery('dashboard-chart', 
    () => Promise.resolve(mockChartData), 
    { refetchInterval: 60000 }
  );

  if (statsLoading || chartLoading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div>
        <h1 className="text-3xl font-bold text-gray-900 dark:text-white">
          Dashboard
        </h1>
        <p className="text-gray-600 dark:text-gray-400">
          Overview of your FinTech AI Platform
        </p>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <StatCard
          title="Total Documents"
          value={stats?.totalDocuments || 0}
          icon={FileText}
          trend="+12% from last month"
          color="bg-blue-500"
        />
        <StatCard
          title="Processed Today"
          value={stats?.processedToday || 0}
          icon={CheckCircle}
          trend="+5% from yesterday"
          color="bg-green-500"
        />
        <StatCard
          title="Pending Processing"
          value={stats?.pendingProcessing || 0}
          icon={Clock}
          color="bg-yellow-500"
        />
        <StatCard
          title="Success Rate"
          value={`${stats?.successRate || 0}%`}
          icon={TrendingUp}
          trend="+2% from last week"
          color="bg-purple-500"
        />
      </div>

      {/* Charts Section */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Activity Chart */}
        <motion.div
          initial={{ opacity: 0, x: -20 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ duration: 0.5, delay: 0.2 }}
          className="bg-white dark:bg-gray-800 rounded-lg shadow-md p-6"
        >
          <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
            Activity Overview
          </h3>
          <ResponsiveContainer width="100%" height={300}>
            <BarChart data={chartData}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="name" />
              <YAxis />
              <Tooltip />
              <Bar dataKey="documents" fill="#3B82F6" />
              <Bar dataKey="transactions" fill="#10B981" />
            </BarChart>
          </ResponsiveContainer>
        </motion.div>

        {/* Document Types Chart */}
        <motion.div
          initial={{ opacity: 0, x: 20 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ duration: 0.5, delay: 0.3 }}
          className="bg-white dark:bg-gray-800 rounded-lg shadow-md p-6"
        >
          <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
            Document Types
          </h3>
          <ResponsiveContainer width="100%" height={300}>
            <PieChart>
              <Pie
                data={mockPieData}
                cx="50%"
                cy="50%"
                labelLine={false}
                label={({ name, percent }) => `${name} ${(percent * 100).toFixed(0)}%`}
                outerRadius={80}
                fill="#8884d8"
                dataKey="value"
              >
                {mockPieData.map((entry, index) => (
                  <Cell key={`cell-${index}`} fill={entry.color} />
                ))}
              </Pie>
              <Tooltip />
            </PieChart>
          </ResponsiveContainer>
        </motion.div>
      </div>

      {/* Recent Activity */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5, delay: 0.4 }}
        className="bg-white dark:bg-gray-800 rounded-lg shadow-md p-6"
      >
        <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
          Recent Activity
        </h3>
        <div className="space-y-4">
          {[
            { action: 'Document processed', document: 'invoice_2024_001.pdf', time: '2 minutes ago', status: 'success' },
            { action: 'Workflow completed', document: 'contract_review', time: '5 minutes ago', status: 'success' },
            { action: 'Suspicious transaction detected', document: 'txn_12345', time: '10 minutes ago', status: 'warning' },
            { action: 'Document uploaded', document: 'receipt_2024_002.pdf', time: '15 minutes ago', status: 'info' },
          ].map((activity, index) => (
            <div key={index} className="flex items-center space-x-4 p-3 bg-gray-50 dark:bg-gray-700 rounded-lg">
              <div className={`w-2 h-2 rounded-full ${
                activity.status === 'success' ? 'bg-green-500' :
                activity.status === 'warning' ? 'bg-yellow-500' : 'bg-blue-500'
              }`} />
              <div className="flex-1">
                <p className="text-sm font-medium text-gray-900 dark:text-white">
                  {activity.action}
                </p>
                <p className="text-xs text-gray-500 dark:text-gray-400">
                  {activity.document}
                </p>
              </div>
              <span className="text-xs text-gray-500 dark:text-gray-400">
                {activity.time}
              </span>
            </div>
          ))}
        </div>
      </motion.div>
    </div>
  );
};

export default Dashboard; 