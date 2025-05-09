import { register, Counter, Histogram } from 'prom-client';

// Create a Registry to register the metrics
const Registry = register;

// Create a counter for HTTP requests
export const httpRequestsTotal = new Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'path', 'status_code']
});

// Create a histogram for request durations
export const httpRequestDurationSeconds = new Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'path', 'status_code'],
  buckets: [0.1, 0.3, 0.5, 0.7, 1, 3, 5, 7, 10] // in seconds
});

// Create a counter for frontend errors
export const frontendErrorsTotal = new Counter({
  name: 'frontend_errors_total',
  help: 'Total number of frontend errors',
  labelNames: ['type']
});

// Create a counter for API errors
export const apiErrorsTotal = new Counter({
  name: 'api_errors_total',
  help: 'Total number of API errors',
  labelNames: ['endpoint', 'status_code']
});

// Create a counter for page views
export const pageViewsTotal = new Counter({
  name: 'page_views_total',
  help: 'Total number of page views',
  labelNames: ['page']
});

// Create a counter for user interactions
export const userInteractionsTotal = new Counter({
  name: 'user_interactions_total',
  help: 'Total number of user interactions',
  labelNames: ['component', 'action']
});

// Function to track API requests with metrics
export const trackApiRequest = async (method, url, options = {}) => {
  const startTime = Date.now();
  let response;
  let error;
  
  try {
    response = await fetch(url, { method, ...options });
    const endTime = Date.now();
    const duration = (endTime - startTime) / 1000; // Convert to seconds
    
    const path = new URL(url).pathname;
    const statusCode = response.status.toString();
    
    // Record metrics
    httpRequestsTotal.inc({ method, path, status_code: statusCode });
    httpRequestDurationSeconds.observe({ method, path, status_code: statusCode }, duration);
    
    if (!response.ok) {
      apiErrorsTotal.inc({ endpoint: path, status_code: statusCode });
    }
    
    return response;
  } catch (err) {
    error = err;
    const path = url ? new URL(url).pathname : 'unknown';
    apiErrorsTotal.inc({ endpoint: path, status_code: 'network_error' });
    frontendErrorsTotal.inc({ type: 'api_error' });
    throw err;
  }
};

// Initialize global error handler
export const initErrorTracking = () => {
  window.addEventListener('error', (event) => {
    frontendErrorsTotal.inc({ type: 'unhandled_error' });
    console.error('Tracked error:', event.error);
  });
  
  window.addEventListener('unhandledrejection', (event) => {
    frontendErrorsTotal.inc({ type: 'unhandled_promise_rejection' });
    console.error('Tracked promise rejection:', event.reason);
  });
};

// Track page view
export const trackPageView = (page) => {
  pageViewsTotal.inc({ page });
};

// Track user interaction
export const trackUserInteraction = (component, action) => {
  userInteractionsTotal.inc({ component, action });
};

// Get metrics in Prometheus format
export const getMetrics = async () => {
  return await Registry.metrics();
};

export default {
  httpRequestsTotal,
  httpRequestDurationSeconds,
  frontendErrorsTotal,
  apiErrorsTotal,
  pageViewsTotal,
  userInteractionsTotal,
  trackApiRequest,
  initErrorTracking,
  trackPageView,
  trackUserInteraction,
  getMetrics
}; 