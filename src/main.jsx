import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';
import { initErrorTracking, trackPageView } from './metrics';

// Initialize metrics tracking
initErrorTracking();

// Track initial page view
trackPageView(window.location.pathname);

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
