#!/bin/bash
# System Status Script for Abstergo Application
# Shows the status of all components including Minikube, application, and monitoring

echo "=== Abstergo System Status ==="

# Check Minikube status
echo "Checking Minikube status..."
MINIKUBE_STATUS=$(minikube status -f '{{.Host}}' 2>/dev/null || echo "Stopped")
if [ "$MINIKUBE_STATUS" == "Running" ]; then
    echo "✅ Minikube: Running"
    
    # Get Minikube resources
    MINIKUBE_MEM=$(minikube config view 2>/dev/null | grep memory | awk '{print $3}' || echo "unknown")
    MINIKUBE_CPU=$(minikube config view 2>/dev/null | grep cpus | awk '{print $3}' || echo "unknown")
    echo "   Memory: ${MINIKUBE_MEM}MB, CPUs: ${MINIKUBE_CPU}"
    
    # Check Kubernetes components
    if kubectl get nodes &>/dev/null; then
        NODE_STATUS=$(kubectl get nodes -o jsonpath='{.items[0].status.conditions[?(@.type=="Ready")].status}')
        if [ "$NODE_STATUS" == "True" ]; then
            echo "✅ Kubernetes: Ready"
        else
            echo "❌ Kubernetes: Not Ready"
        fi
        
        # Check application deployment
        if kubectl get deployment abstergo-app &>/dev/null; then
            REPLICAS=$(kubectl get deployment abstergo-app -o jsonpath='{.status.readyReplicas}')
            TOTAL_REPLICAS=$(kubectl get deployment abstergo-app -o jsonpath='{.spec.replicas}')
            if [ "$REPLICAS" == "$TOTAL_REPLICAS" ]; then
                echo "✅ Abstergo App: Running ($REPLICAS/$TOTAL_REPLICAS replicas ready)"
            else
                echo "⚠️ Abstergo App: Partially Running ($REPLICAS/$TOTAL_REPLICAS replicas ready)"
            fi
            
            # Get app URL
            if kubectl get service abstergo-service &>/dev/null; then
                NODE_PORT=$(kubectl get service abstergo-service -o jsonpath='{.spec.ports[0].nodePort}')
                MINIKUBE_IP=$(minikube ip)
                echo "   App URL: http://$MINIKUBE_IP:$NODE_PORT"
            fi
        else
            echo "❌ Abstergo App: Not Deployed"
        fi
        
        # Check monitoring
        if kubectl get namespace monitoring &>/dev/null; then
            GRAFANA_READY=$(kubectl get pods -n monitoring -l "app.kubernetes.io/name=grafana" -o jsonpath="{.items[0].status.containerStatuses[?(@.ready==true)].ready}" 2>/dev/null | wc -w)
            PROM_READY=$(kubectl get pods -n monitoring -l "app=prometheus" -o jsonpath="{.items[0].status.containerStatuses[?(@.ready==true)].ready}" 2>/dev/null | wc -w)
            
            if [ "$GRAFANA_READY" -gt 0 ] && [ "$PROM_READY" -gt 0 ]; then
                echo "✅ Monitoring: Active"
                echo "   To access dashboards: ./scripts/access_monitoring.sh"
            else
                echo "⚠️ Monitoring: Partially Running"
                echo "   Some monitoring pods are not ready"
                echo "   To check: kubectl get pods -n monitoring"
            fi
        else
            echo "❌ Monitoring: Not Installed"
            echo "   To install: ./scripts/install_minimal_monitoring.sh"
        fi
    else
        echo "❌ Kubernetes: Not Accessible"
    fi
else
    echo "❌ Minikube: Stopped"
    echo "   To start: minikube start"
    echo "   Note: Starting Minikube requires significant resources"
    echo "   (Recommended: At least 2GB RAM and 2 CPU cores)"
    
    echo "⚠️ Abstergo App: Inactive (Minikube stopped)"
    echo "⚠️ Monitoring: Inactive (Minikube stopped)"
fi

echo ""
echo "=== System Resource Usage ==="
echo "Current memory usage:"
free -h | grep "Mem:" | awk '{print "   Total: " $2 ", Used: " $3 ", Free: " $4}'

echo "Current CPU load:"
uptime | awk '{print "   " $0}'

echo ""
echo "=== Available Scripts ==="
echo "• ./scripts/check_monitoring_status.sh - Check monitoring status"
echo "• ./scripts/access_monitoring.sh - Access monitoring dashboards (requires Minikube running)"
echo "• ./scripts/generate_test_data.sh - Generate test traffic to the application"
echo "• ./scripts/system_status.sh - Show this system status" 