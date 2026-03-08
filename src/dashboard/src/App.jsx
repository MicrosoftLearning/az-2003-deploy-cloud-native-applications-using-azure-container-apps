import { useState } from 'react'

// Ingestion service URL for load testing
// Uses VITE_INGESTION_URL from environment, or derives from current hostname
const getIngestionUrl = () => {
  if (import.meta.env.VITE_INGESTION_URL) {
    return import.meta.env.VITE_INGESTION_URL
  }
  // Derive from current hostname by replacing 'dashboard' with 'ingestion-service'
  if (typeof window !== 'undefined' && window.location.hostname.includes('azurecontainerapps.io')) {
    return window.location.origin.replace('dashboard', 'ingestion-service')
  }
  return 'http://localhost:8000'
}
const INGESTION_URL = getIngestionUrl()

// Styles
const styles = {
  container: {
    maxWidth: '1400px',
    margin: '0 auto',
    padding: '24px',
  },
  header: {
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: '32px',
    flexWrap: 'wrap',
    gap: '16px',
  },
  title: {
    fontSize: '28px',
    fontWeight: '700',
    background: 'linear-gradient(90deg, #00d4ff, #7c3aed)',
    WebkitBackgroundClip: 'text',
    WebkitTextFillColor: 'transparent',
  },
  badge: {
    background: '#22c55e',
    color: 'white',
    padding: '4px 12px',
    borderRadius: '12px',
    fontSize: '12px',
    fontWeight: '600',
  },
  grid: {
    display: 'grid',
    gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))',
    gap: '24px',
    marginBottom: '32px',
  },
  card: {
    background: 'rgba(255, 255, 255, 0.05)',
    backdropFilter: 'blur(10px)',
    borderRadius: '16px',
    padding: '24px',
    border: '1px solid rgba(255, 255, 255, 0.1)',
  },
  cardTitle: {
    fontSize: '14px',
    color: '#9ca3af',
    marginBottom: '8px',
    textTransform: 'uppercase',
    letterSpacing: '1px',
  },
  cardValue: {
    fontSize: '36px',
    fontWeight: '700',
    marginBottom: '4px',
  },
  cardSubtext: {
    fontSize: '12px',
    color: '#6b7280',
  },
  metricsCard: {
    background: 'rgba(255, 255, 255, 0.05)',
    backdropFilter: 'blur(10px)',
    borderRadius: '16px',
    padding: '24px',
    border: '1px solid rgba(255, 255, 255, 0.1)',
    marginBottom: '32px',
  },
  metricsTitle: {
    fontSize: '18px',
    fontWeight: '600',
    marginBottom: '20px',
    display: 'flex',
    alignItems: 'center',
    gap: '8px',
  },
  button: {
    background: 'linear-gradient(90deg, #ef4444, #dc2626)',
    border: 'none',
    padding: '16px 32px',
    borderRadius: '8px',
    color: 'white',
    fontWeight: '600',
    fontSize: '16px',
    cursor: 'pointer',
    transition: 'transform 0.2s, box-shadow 0.2s',
  },
  differentiatorList: {
    listStyle: 'none',
    padding: 0,
  },
  differentiatorItem: {
    display: 'flex',
    alignItems: 'center',
    gap: '12px',
    padding: '16px',
    background: 'rgba(34, 197, 94, 0.1)',
    borderRadius: '8px',
    marginBottom: '12px',
    border: '1px solid rgba(34, 197, 94, 0.2)',
  },
  checkIcon: {
    width: '24px',
    height: '24px',
    background: '#22c55e',
    borderRadius: '50%',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    fontSize: '14px',
  },
}

function App() {
  const [simulating, setSimulating] = useState(false)
  const [loadTestStatus, setLoadTestStatus] = useState('')

  async function simulateHeavyLoad() {
    setSimulating(true)
    setLoadTestStatus(`Starting load test... (Target: ${INGESTION_URL})`)
    const totalEvents = 100
    const concurrentLimit = 30
    
    let inFlight = 0
    let completed = 0
    let errors = 0
    
    const sendRequest = async () => {
      inFlight++
      try {
        const response = await fetch(`${INGESTION_URL}/simulate`, { 
          method: 'POST',
          mode: 'cors',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            deviceId: `load-test-${Date.now()}`,
            value: Math.random() * 100
          })
        })
        if (!response.ok) {
          errors++
          console.error('Request failed:', response.status)
        }
      } catch (err) {
        errors++
        console.error('Error:', err)
      } finally {
        inFlight--
        completed++
        setLoadTestStatus(`Sending events: ${completed}/${totalEvents}${errors > 0 ? ` (${errors} errors)` : ''}`)
      }
    }
    
    const promises = []
    for (let i = 0; i < totalEvents; i++) {
      while (inFlight >= concurrentLimit) {
        await new Promise(r => setTimeout(r, 50))
      }
      promises.push(sendRequest())
    }
    
    await Promise.all(promises)
    setLoadTestStatus(`✅ Complete! ${totalEvents} events sent. Check Azure Portal for replica count.`)
    setSimulating(false)
  }

  return (
    <div style={styles.container}>
      {/* Header */}
      <header style={styles.header}>
        <div>
          <h1 style={styles.title}>☁️ Contoso Analytics</h1>
          <p style={{ color: '#9ca3af', marginTop: '4px' }}>
            Auto-Scaling Demo on Azure Container Apps
          </p>
        </div>
        <span style={styles.badge}>● Live</span>
      </header>

      {/* Load Test Simulator */}
      <div style={styles.metricsCard}>
        <div style={styles.metricsTitle}>
          🔥 Load Test - Trigger Auto-Scaling
        </div>
        <p style={{ color: '#9ca3af', marginBottom: '20px' }}>
          Send 100 concurrent events to the ingestion-service to trigger replica scaling.
          <br />
          <span style={{ fontSize: '13px' }}>
            After clicking, check Azure Portal → ingestion-service → Replicas to see scaling in action.
          </span>
        </p>
        
        <button
          style={{ ...styles.button, opacity: simulating ? 0.7 : 1 }}
          onClick={simulateHeavyLoad}
          disabled={simulating}
        >
          {simulating ? '🔄 Sending Events...' : '🔥 Send 100 Events (Heavy Load)'}
        </button>
        
        {loadTestStatus && (
          <p style={{ 
            color: loadTestStatus.includes('✅') ? '#22c55e' : '#f59e0b', 
            marginTop: '16px', 
            fontSize: '14px',
            fontWeight: '500'
          }}>
            {loadTestStatus}
          </p>
        )}
      </div>

      {/* Architecture */}
      <div style={styles.metricsCard}>
        <div style={styles.metricsTitle}>
          🏗️ Demo Architecture
        </div>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '12px' }}>
          {[
            { name: 'Dashboard', type: 'container-app', description: 'React UI - This page' },
            { name: 'Ingestion Service', type: 'container-app', description: '.NET 8 - HTTP Auto-Scaling' },
          ].map((comp, i) => (
            <div key={i} style={{
              padding: '16px',
              background: comp.type === 'azure' ? 'rgba(0, 120, 212, 0.2)' : 'rgba(124, 58, 237, 0.2)',
              borderRadius: '8px',
              border: `1px solid ${comp.type === 'azure' ? 'rgba(0, 120, 212, 0.3)' : 'rgba(124, 58, 237, 0.3)'}`,
            }}>
              <div style={{ fontWeight: '600', marginBottom: '4px' }}>{comp.name}</div>
              <div style={{ fontSize: '12px', color: '#9ca3af' }}>{comp.description}</div>
            </div>
          ))}
        </div>
      </div>

      {/* Footer */}
      <footer style={{ textAlign: 'center', color: '#6b7280', padding: '24px 0' }}>
        <p>Azure Container Apps Auto-Scaling Demo</p>
        <p style={{ marginTop: '8px', fontSize: '14px' }}>
          Deploy with: <code style={{ background: 'rgba(255,255,255,0.1)', padding: '4px 8px', borderRadius: '4px' }}>azd up</code>
        </p>
      </footer>
    </div>
  )
}

export default App
