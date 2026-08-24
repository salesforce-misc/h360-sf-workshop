import { Outlet, Link, useLocation } from 'react-router';
import { getAllRoutes } from './router-utils';
import { useState } from 'react';
import { AgentforceChat } from './components/AgentforceChat';

export default function AppLayout() {
  const [isOpen, setIsOpen] = useState(false);
  const location = useLocation();

  const isActive = (path: string) => location.pathname === path;

  const toggleMenu = () => setIsOpen(!isOpen);

  const navigationRoutes: { path: string; label: string }[] = getAllRoutes()
    .filter(
      route =>
        route.handle?.showInNavigation === true &&
        route.fullPath !== undefined &&
        route.handle?.label !== undefined
    )
    .map(
      route =>
        ({
          path: route.fullPath,
          label: route.handle?.label,
        }) as { path: string; label: string }
    );

  return (
    <>
      <nav className="bg-secondary border-b-2 border-accent">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center h-16">
            <Link to="/" className="text-xl font-semibold text-primary">
              Headless 360 Workshop
            </Link>
            <button
              onClick={toggleMenu}
              className="p-2 rounded-md text-primary hover:bg-white focus:outline-none focus:ring-2 focus:ring-accent"
              aria-label="Toggle menu"
            >
              <div className="w-6 h-6 flex flex-col justify-center space-y-1.5">
                <span
                  className={`block h-0.5 w-6 bg-current transition-all ${
                    isOpen ? 'rotate-45 translate-y-2' : ''
                  }`}
                />
                <span
                  className={`block h-0.5 w-6 bg-current transition-all ${isOpen ? 'opacity-0' : ''}`}
                />
                <span
                  className={`block h-0.5 w-6 bg-current transition-all ${
                    isOpen ? '-rotate-45 -translate-y-2' : ''
                  }`}
                />
              </div>
            </button>
          </div>
          {isOpen && (
            <div className="pb-4">
              <div className="flex flex-col space-y-2">
                {navigationRoutes.map(item => (
                  <Link
                    key={item.path}
                    to={item.path}
                    onClick={() => setIsOpen(false)}
                    className={`px-3 py-2 rounded-md text-sm font-medium transition-colors ${
                      isActive(item.path)
                        ? 'bg-accent text-accent-foreground'
                        : 'text-primary hover:bg-white'
                    }`}
                  >
                    {item.label}
                  </Link>
                ))}
              </div>
            </div>
          )}
        </div>
      </nav>
      <Outlet />
      <AgentforceChat />
    </>
  );
}
