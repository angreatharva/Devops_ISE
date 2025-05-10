#!/bin/bash
# Script to check the status of the monitoring setup

echo "=== Abstergo Monitoring Status Check ==="
echo "Checking all components of the monitoring stack..."
echo ""

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "ERROR: kubectl not found. Please install kubectl."
    exit 1
fi

# Check if Kubernetes is accessible
echo "Checking Kubernetes connection..."
if ! kubectl cluster-info &> /dev/null; then
    echo "ERROR: Cannot connect to Kubernetes cluster."
    echo "Please check your kubeconfig file or cluster status."
    exit 1
fi

# Check if monitoring namespace exists
if ! kubectl get namespace monitoring &> /dev/null; then
    echo "ERROR: Monitoring namespace not found."
    echo "Run scripts/install_minimal_monitoring.sh to install monitoring"
    exit 1
fi

# Function to check component status
check_component() {
    local component=$1
    local namespace=$2
    local label=$3
    
    echo "Checking $component..."
    
    # Check if pods exist
    POD_COUNT=$(kubectl get pods -n $namespace -l $label --no-headers 2>/dev/null | wc -l)
    
    if [ "$POD_COUNT" -eq 0 ]; then
        echo "  - Status: NOT INSTALLED"
        return 1
    fi
    
    # Check pod status
    RUNNING_COUNT=$(kubectl get pods -n $namespace -l $label -o jsonpath='{range .items[*]}{.status.phase}{"\n"}{end}' | grep -c "Running")
    
    if [ "$RUNNING_COUNT" -eq "$POD_COUNT" ]; then
        echo "  - Status: RUNNING ($RUNNING_COUNT/$POD_COUNT pods)"
        
        # Check resource usage if possible
        if command -v kubectl &> /dev/null; then
            echo "  - Resources:"
            kubectl top pods -n $namespace -l $label 2>/dev/null || echo "    (Resource metrics not available)"
        fi
        
        return 0
    else
        echo "  - Status: PARTIALLY RUNNING ($RUNNING_COUNT/$POD_COUNT pods)"
        
        # Show problematic pods
        echo "  - Problematic pods:"
        kubectl get pods -n $namespace -l $label -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.phase}{"\n"}{end}' | grep -v "Running"
        
        return 2
    fi
}

# Check Prometheus
echo "=== Prometheus ==="
check_component "Prometheus" "monitoring" "app=prometheus"
PROMETHEUS_STATUS=$?

# Check Grafana
echo ""
echo "=== Grafana ==="
check_component "Grafana" "monitoring" "app.kubernetes.io/name=grafana"
GRAFANA_STATUS=$?

# Check ServiceMonitor
echo ""
echo "=== ServiceMonitor ==="
if kubectl get servicemonitor abstergo-app-monitor -n monitoring &> /dev/null; then
    echo "  - Status: CONFIGURED"
    
    # Check if ServiceMonitor is selecting the right service
    SELECTOR=$(kubectl get servicemonitor abstergo-app-monitor -n monitoring -o jsonpath='{.spec.selector.matchLabels}')
    echo "  - Selector: $SELECTOR"
    
    # Check if any services match this selector
    MATCHING_SERVICES=$(kubectl get services --all-namespaces -l app=abstergo-app -o name 2>/dev/null | wc -l)
    if [ "$MATCHING_SERVICES" -gt 0 ]; then
        echo "  - Matching services: $MATCHING_SERVICES"
    else
        echo "  - WARNING: No services match the ServiceMonitor selector"
    fi
else
    echo "  - Status: NOT CONFIGURED"
    echo "  - Run: kubectl apply -f ../k8s/servicemonitor.yaml"
fi

# Check Abstergo application
echo ""
echo "=== Abstergo Application ==="
if kubectl get deployment abstergo-app &> /dev/null; then
    READY=$(kubectl get deployment abstergo-app -o jsonpath='{.status.readyReplicas}')
    TOTAL=$(kubectl get deployment abstergo-app -o jsonpath='{.status.replicas}')
    
    if [ "$READY" -eq "$TOTAL" ]; then
        echo "  - Status: RUNNING ($READY/$TOTAL replicas ready)"
    else
        echo "  - Status: PARTIALLY RUNNING ($READY/$TOTAL replicas ready)"
    fi
    
    # Check metrics endpoint
    echo "  - Checking metrics endpoint..."
    METRICS_PORT=$(kubectl get svc abstergo-service -o jsonpath='{.spec.ports[?(@.name=="metrics")].port}' 2>/dev/null)
    
    if [ -n "$METRICS_PORT" ]; then
        echo "  - Metrics port: $METRICS_PORT"
        
        # Try to port-forward and check metrics
        echo "  - Attempting to check metrics availability..."
        kubectl port-forward svc/abstergo-service $METRICS_PORT:$METRICS_PORT > /dev/null 2>&1 &
        PF_PID=$!
        
        # Give port-forwarding time to establish
        sleep 3
        
        # Check if metrics are accessible
        if curl -s localhost:$METRICS_PORT/metrics > /dev/null; then
            echo "  - Metrics endpoint: ACCESSIBLE"
        else
            echo "  - Metrics endpoint: NOT ACCESSIBLE"
        fi
        
        # Kill port-forwarding
        kill $PF_PID 2>/dev/null
    else
        echo "  - Metrics port: NOT CONFIGURED"
    fi
else
    echo "  - Status: NOT RUNNING"
fi

# Check alerts
echo ""
echo "=== Prometheus Alerts ==="
if kubectl get prometheusrules abstergo-alerts -n monitoring &> /dev/null; then
    echo "  - Status: CONFIGURED"
    
    # Count alerts
    ALERT_COUNT=$(kubectl get prometheusrules abstergo-alerts -n monitoring -o jsonpath='{.spec.groups[0].rules[*].alert}' | wc -w)
    echo "  - Configured alerts: $ALERT_COUNT"
else
    echo "  - Status: NOT CONFIGURED"
    echo "  - Run: ./scripts/apply_alerts.sh"
fi

# Summary
echo ""
echo "=== Summary ==="
if [ $PROMETHEUS_STATUS -eq 0 ] && [ $GRAFANA_STATUS -eq 0 ]; then
    echo "Monitoring stack is running properly."
    
    # Get access information
    GRAFANA_USER="admin"
    GRAFANA_PASSWORD=$(kubectl get secret -n monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode 2>/dev/null)
    
    if [ -n "$GRAFANA_PASSWORD" ]; then
        echo ""
        echo "=== Access Information ==="
        echo "To access dashboards, run: ./scripts/access_monitoring.sh"
        echo ""
        echo "Grafana credentials:"
        echo "  Username: $GRAFANA_USER"
        echo "  Password: $GRAFANA_PASSWORD"
    fi
else
    echo "Monitoring stack has issues. Please check the details above."
fi

echo ""
echo "For more information, see monitoring/MONITORING_GUIDE.md" 