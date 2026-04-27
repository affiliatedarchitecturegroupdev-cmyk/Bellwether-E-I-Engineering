# BEIE Nexus API Reference

This document provides comprehensive API documentation for BEIE Nexus.

## Overview

BEIE Nexus uses a RESTful API architecture with the following principles:
- JSON-based request/response format
- Standard HTTP status codes
- Consistent error response format
- Versioned endpoints (`/api/v1/`)
- Pagination for list endpoints
- Rate limiting enforced

## Base URL

```
https://api.beie.co.za/api/v1
```

## Authentication

All API requests require authentication via JWT token in the Authorization header:

```
Authorization: Bearer <jwt_token>
```

Tokens are obtained through the authentication endpoints.

## Response Format

### Success Response

```json
{
  "data": <payload>,
  "meta": {
    "requestId": "uuid-v7",
    "timestamp": "2026-04-27T10:00:00Z"
  }
}
```

### Error Response

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Validation failed",
    "details": [
      {
        "field": "email",
        "message": "Invalid email format"
      }
    ],
    "requestId": "uuid-v7",
    "timestamp": "2026-04-27T10:00:00Z"
  }
}
```

### Pagination

List endpoints support pagination:

```json
{
  "data": [...],
  "meta": {
    "page": 1,
    "perPage": 25,
    "total": 150,
    "totalPages": 6,
    "requestId": "uuid-v7",
    "timestamp": "2026-04-27T10:00:00Z"
  }
}
```

Query parameters:
- `page`: Page number (default: 1)
- `perPage`: Items per page (default: 25, max: 100)

## Endpoints

### Authentication

#### POST /auth/login
Authenticate user and return JWT tokens.

**Request:**
```json
{
  "email": "user@beie.co.za",
  "password": "password",
  "totpCode": "123456"  // Optional, for MFA
}
```

**Response:**
```json
{
  "data": {
    "accessToken": "jwt_access_token",
    "refreshToken": "jwt_refresh_token",
    "expiresIn": 900,
    "user": {
      "id": "uuid",
      "email": "user@beie.co.za",
      "firstName": "John",
      "lastName": "Doe",
      "role": "engineer"
    }
  }
}
```

#### POST /auth/refresh
Refresh access token using refresh token.

**Request:**
```json
{
  "refreshToken": "jwt_refresh_token"
}
```

**Response:**
```json
{
  "data": {
    "accessToken": "new_jwt_access_token",
    "expiresIn": 900
  }
}
```

### Projects

#### GET /projects
List projects accessible to the authenticated user.

**Query Parameters:**
- `status`: Filter by status
- `clientId`: Filter by client
- `page`: Page number
- `perPage`: Items per page

**Response:**
```json
{
  "data": [
    {
      "id": "uuid",
      "code": "BEIE-2026-0042",
      "name": "Electrical Installation - Office Building",
      "status": "active",
      "client": {
        "id": "uuid",
        "name": "ABC Construction"
      },
      "financials": {
        "contractValue": 150000.00,
        "invoicedToDate": 75000.00
      },
      "createdAt": "2026-04-01T00:00:00Z"
    }
  ],
  "meta": {
    "page": 1,
    "perPage": 25,
    "total": 1,
    "requestId": "uuid",
    "timestamp": "2026-04-27T10:00:00Z"
  }
}
```

#### GET /projects/{id}
Get detailed project information.

#### POST /projects
Create a new project.

#### PUT /projects/{id}
Update project information.

#### DELETE /projects/{id}
Archive a project.

### Tasks

#### GET /projects/{projectId}/tasks
List tasks for a project.

#### POST /projects/{projectId}/tasks
Create a new task.

#### PUT /tasks/{id}
Update task status or details.

### E-Commerce

#### GET /catalogue/products
List products in the catalogue.

**Query Parameters:**
- `category`: Filter by category
- `search`: Full-text search
- `page`: Page number
- `perPage`: Items per page

#### GET /catalogue/products/{sku}
Get product details.

#### POST /cart/items
Add item to cart.

#### PUT /cart/items/{sku}
Update cart item quantity.

#### DELETE /cart/items/{sku}
Remove item from cart.

#### POST /orders
Create order from cart.

### AI Services

#### POST /ai/estimate
Request project cost estimate from AI.

**Request:**
```json
{
  "projectDescription": "Electrical installation for 5000sqm office building",
  "requirements": ["Lighting", "Power distribution", "Earthing"],
  "budget": 200000
}
```

#### POST /ai/compliance/check
Check design compliance with SANS standards.

#### GET /ai/tasks/{id}
Get status of async AI task.

### Blockchain

#### GET /verify/{txHash}
Verify blockchain-anchored document.

Returns verification details including:
- Transaction hash
- Timestamp
- Document hash
- IPFS link

## Rate Limiting

- **Authenticated requests**: 1000 per minute per user
- **Unauthenticated requests**: 100 per minute per IP
- **AI endpoints**: 10 per minute per user

Rate limit headers included in responses:
```
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 999
X-RateLimit-Reset: 1640995200
```

## Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| `VALIDATION_ERROR` | 400 | Request validation failed |
| `UNAUTHORIZED` | 401 | Authentication required |
| `FORBIDDEN` | 403 | Insufficient permissions |
| `NOT_FOUND` | 404 | Resource not found |
| `CONFLICT` | 409 | Resource conflict |
| `RATE_LIMITED` | 429 | Too many requests |
| `INTERNAL_ERROR` | 500 | Server error |

## SDKs & Libraries

- **JavaScript/TypeScript**: Official SDK available on npm
- **Python**: AI service integration library
- **Postman Collection**: Available for testing

## Changelog

### v1.0.0 (Current)
- Initial API release
- Authentication endpoints
- Project management
- E-commerce catalogue
- AI services integration
- Blockchain verification

## Support

For API support:
- Email: api-support@beie.co.za
- Documentation: https://docs.beie.co.za
- Status page: https://status.beie.co.za