// Simple metrics tracking for frontend
const metrics = {
  httpRequests: {},
  errors: {},
  pageViews: {},
  userInteractions: {}
};

// Track API requests
export const trackApiRequest = async (method, url, options = {}) => {
  const startTime = Date.now();
  let response;
  
  try {
    response = await fetch(url, { method, ...options });
    const endTime = Date.now();
    const duration = (endTime - startTime) / 1000;
    
    const path = new URL(url).pathname;
    const statusCode = response.status.toString();
    
    // Record metrics
    if (!metrics.httpRequests[path]) {
      metrics.httpRequests[path] = {
        total: 0,
        errors: 0,
        duration: 0
      };
    }
    
    metrics.httpRequests[path].total++;
    metrics.httpRequests[path].duration += duration;
    
    if (!response.ok) {
      metrics.httpRequests[path].errors++;
    }
    
    return response;
  } catch (err) {
    if (!metrics.errors[url]) {
      metrics.errors[url] = 0;
    }
    metrics.errors[url]++;
    throw err;
  }
};

// Track page views
export const trackPageView = (page) => {
  if (!metrics.pageViews[page]) {
    metrics.pageViews[page] = 0;
  }
  metrics.pageViews[page]++;
};

// Track user interactions
export const trackUserInteraction = (component, action) => {
  const key = `${component}:${action}`;
  if (!metrics.userInteractions[key]) {
    metrics.userInteractions[key] = 0;
  }
  metrics.userInteractions[key]++;
};

// Initialize error tracking
export const initErrorTracking = () => {
  window.addEventListener('error', (event) => {
    if (!metrics.errors['unhandled']) {
      metrics.errors['unhandled'] = 0;
    }
    metrics.errors['unhandled']++;
    console.error('Tracked error:', event.error);
  });
  
  window.addEventListener('unhandledrejection', (event) => {
    if (!metrics.errors['unhandled_promise']) {
      metrics.errors['unhandled_promise'] = 0;
    }
    metrics.errors['unhandled_promise']++;
    console.error('Tracked promise rejection:', event.reason);
  });
};

// Get metrics data
export const getMetrics = () => {
  return metrics;
};

export default {
  trackApiRequest,
  trackPageView,
  trackUserInteraction,
  initErrorTracking,
  getMetrics
}; 