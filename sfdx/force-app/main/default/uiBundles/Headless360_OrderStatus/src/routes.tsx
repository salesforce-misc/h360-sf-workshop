import type { RouteObject } from 'react-router';
import AppLayout from '@/appLayout';
import Home from './pages/Home';
import OrderStatus from './pages/OrderStatus';
import NotFound from './pages/NotFound';

export const routes: RouteObject[] = [
  {
    path: '/',
    element: <AppLayout />,
    children: [
      {
        index: true,
        element: <Home />,
        handle: { showInNavigation: true, label: 'Home' },
      },
      {
        path: 'orders',
        element: <OrderStatus />,
        handle: { showInNavigation: true, label: 'Orders' },
      },
      {
        path: '*',
        element: <NotFound />,
      },
    ],
  },
];
