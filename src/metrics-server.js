import express from 'express';
import cors from 'cors';
import { getMetrics } from './metrics.js';

// Create Express server
const app = express();
app.use(cors());

// Metrics endpoint
app.get('/metrics', async (req, res) => {
  try {
    const metrics = await getMetrics();
    res.set('Content-Type', 'text/plain');
    res.send(metrics);
  } catch (error) {
    console.error('Error generating metrics:', error);
    res.status(500).send('Error generating metrics');
  }
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).send('OK');
});

// Start server
const PORT = process.env.METRICS_PORT || 9113;
app.listen(PORT, () => {
  console.log(`Metrics server listening on port ${PORT}`);
});

export default app; 