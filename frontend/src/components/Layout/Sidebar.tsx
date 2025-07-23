import React, { useState } from 'react';
import { NavLink, useLocation } from 'react-router-dom';
import { 
  Home, 
  FileText, 
  BarChart3, 
  Workflow, 
  Settings, 
  Menu, 
  X,
  ChevronDown,
  ChevronRight
} from 'lucide-react';
import { useAuth } from '../../contexts/AuthContext';

interface MenuItem {
  name: string;
  path: string;
  icon: React.ComponentType<{ className?: string }>;
  children?: MenuItem[];
}

const menuItems: MenuItem[] = [
  {
    name: 'Dashboard',
    path: '/',
    icon: Home,
  },
  {
    name: 'Documents',
    path: '/documents',
    icon: FileText,
    children: [
      { name: 'Upload', path: '/documents/upload', icon: FileText },
      { name: 'Process', path: '/documents/process', icon: FileText },
      { name: 'History', path: '/documents/history', icon: FileText },
    ],
  },
  {
    name: 'Analytics',
    path: '/analytics',
    icon: BarChart3,
    children: [
      { name: 'Overview', path: '/analytics/overview', icon: BarChart3 },
      { name: 'Reports', path: '/analytics/reports', icon: BarChart3 },
      { name: 'Insights', path: '/analytics/insights', icon: BarChart3 },
    ],
  },
  {
    name: 'Workflows',
    path: '/workflows',
    icon: Workflow,
    children: [
      { name: 'Create', path: '/workflows/create', icon: Workflow },
      { name: 'Manage', path: '/workflows/manage', icon: Workflow },
      { name: 'Monitor', path: '/workflows/monitor', icon: Workflow },
    ],
  },
  {
    name: 'Settings',
    path: '/settings',
    icon: Settings,
  },
];

const Sidebar: React.FC = () => {
  const [isCollapsed, setIsCollapsed] = useState(false);
  const [expandedItems, setExpandedItems] = useState<string[]>([]);
  const location = useLocation();
  const { user } = useAuth();

  const toggleExpanded = (itemName: string) => {
    setExpandedItems(prev => 
      prev.includes(itemName) 
        ? prev.filter(name => name !== itemName)
        : [...prev, itemName]
    );
  };

  const isExpanded = (itemName: string) => expandedItems.includes(itemName);

  const renderMenuItem = (item: MenuItem, level: number = 0) => {
    const Icon = item.icon;
    const hasChildren = item.children && item.children.length > 0;
    const isActive = location.pathname === item.path;
    const isExpandedItem = isExpanded(item.name);

    return (
      <div key={item.path}>
        <NavLink
          to={item.path}
          className={({ isActive }) =>
            `flex items-center px-4 py-2 text-sm font-medium rounded-md transition-colors duration-200 ${
              isActive
                ? 'bg-blue-100 text-blue-700 dark:bg-blue-900 dark:text-blue-300'
                : 'text-gray-600 hover:bg-gray-100 hover:text-gray-900 dark:text-gray-300 dark:hover:bg-gray-700 dark:hover:text-white'
            }`
          }
          onClick={() => {
            if (hasChildren) {
              toggleExpanded(item.name);
            }
          }}
        >
          <Icon className="w-5 h-5 mr-3" />
          {!isCollapsed && (
            <>
              <span className="flex-1">{item.name}</span>
              {hasChildren && (
                isExpandedItem ? (
                  <ChevronDown className="w-4 h-4" />
                ) : (
                  <ChevronRight className="w-4 h-4" />
                )
              )}
            </>
          )}
        </NavLink>
        
        {hasChildren && isExpandedItem && !isCollapsed && (
          <div className="ml-4 mt-1 space-y-1">
            {item.children!.map(child => renderMenuItem(child, level + 1))}
          </div>
        )}
      </div>
    );
  };

  return (
    <div className={`bg-white dark:bg-gray-800 shadow-lg transition-all duration-300 ${
      isCollapsed ? 'w-16' : 'w-64'
    }`}>
      {/* Header */}
      <div className="flex items-center justify-between p-4 border-b border-gray-200 dark:border-gray-700">
        {!isCollapsed && (
          <h1 className="text-xl font-bold text-gray-900 dark:text-white">
            FinTech AI
          </h1>
        )}
        <button
          onClick={() => setIsCollapsed(!isCollapsed)}
          className="p-2 rounded-md text-gray-400 hover:text-gray-600 hover:bg-gray-100 dark:hover:bg-gray-700"
        >
          {isCollapsed ? <Menu className="w-5 h-5" /> : <X className="w-5 h-5" />}
        </button>
      </div>

      {/* User info */}
      {!isCollapsed && user && (
        <div className="p-4 border-b border-gray-200 dark:border-gray-700">
          <div className="flex items-center">
            <div className="w-8 h-8 bg-blue-500 rounded-full flex items-center justify-center">
              <span className="text-white text-sm font-medium">
                {user.name?.charAt(0) || 'U'}
              </span>
            </div>
            <div className="ml-3">
              <p className="text-sm font-medium text-gray-900 dark:text-white">
                {user.name || 'User'}
              </p>
              <p className="text-xs text-gray-500 dark:text-gray-400">
                {user.email || 'user@example.com'}
              </p>
            </div>
          </div>
        </div>
      )}

      {/* Navigation */}
      <nav className="p-4 space-y-2">
        {menuItems.map(item => renderMenuItem(item))}
      </nav>
    </div>
  );
};

export default Sidebar; 