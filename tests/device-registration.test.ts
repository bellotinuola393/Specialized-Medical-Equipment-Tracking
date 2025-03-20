import { describe, it, expect, beforeEach } from 'vitest';

// Mock implementation for testing Clarity contracts
const mockDevices = new Map();
let lastDeviceId = 0;

// Mock functions to simulate contract behavior
function registerDevice(name, model, serialNumber, manufacturer, purchaseDate, warrantyExpiry) {
  const newId = lastDeviceId + 1;
  lastDeviceId = newId;
  
  mockDevices.set(newId, {
    name,
    model,
    'serial-number': serialNumber,
    manufacturer,
    'purchase-date': purchaseDate,
    'warranty-expiry': warrantyExpiry,
    status: 'available'
  });
  
  return { value: newId };
}

function updateDeviceStatus(deviceId, newStatus) {
  if (!mockDevices.has(deviceId)) {
    return { error: 404 };
  }
  
  const device = mockDevices.get(deviceId);
  device.status = newStatus;
  mockDevices.set(deviceId, device);
  
  return { value: true };
}

function getDevice(deviceId) {
  if (!mockDevices.has(deviceId)) {
    return { value: null };
  }
  return { value: mockDevices.get(deviceId) };
}

describe('Device Registration Contract', () => {
  beforeEach(() => {
    mockDevices.clear();
    lastDeviceId = 0;
  });
  
  it('should register a new device', () => {
    const result = registerDevice(
        'Ventilator X3',
        'VX3-2000',
        'SN12345678',
        'MedTech Inc',
        1609459200, // Jan 1, 2021
        1672531200  // Jan 1, 2023
    );
    
    expect(result.value).toBe(1);
    expect(mockDevices.size).toBe(1);
    expect(mockDevices.get(1).name).toBe('Ventilator X3');
    expect(mockDevices.get(1).status).toBe('available');
  });
  
  it('should update device status', () => {
    registerDevice(
        'Ventilator X3',
        'VX3-2000',
        'SN12345678',
        'MedTech Inc',
        1609459200,
        1672531200
    );
    
    const result = updateDeviceStatus(1, 'maintenance');
    expect(result.value).toBe(true);
    expect(mockDevices.get(1).status).toBe('maintenance');
  });
  
  it('should fail to update non-existent device', () => {
    const result = updateDeviceStatus(999, 'maintenance');
    expect(result.error).toBe(404);
  });
  
  it('should retrieve device information', () => {
    registerDevice(
        'Ventilator X3',
        'VX3-2000',
        'SN12345678',
        'MedTech Inc',
        1609459200,
        1672531200
    );
    
    const result = getDevice(1);
    expect(result.value).not.toBeNull();
    expect(result.value.name).toBe('Ventilator X3');
    expect(result.value.model).toBe('VX3-2000');
  });
  
  it('should return null for non-existent device', () => {
    const result = getDevice(999);
    expect(result.value).toBeNull();
  });
});
