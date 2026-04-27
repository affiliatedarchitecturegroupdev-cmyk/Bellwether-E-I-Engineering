# Internationalization Setup

This document outlines the internationalization (i18n) and localization (l10n) setup for BEIE Nexus.

## Supported Languages

### Primary Languages
- **English (en)**: Default language, South African English
- **Afrikaans (af)**: Primary additional language for South African market
- **Zulu (zu)**: Additional South African language
- **Xhosa (xh)**: Additional South African language

### Future Languages
- **Portuguese (pt)**: For Lusophone African markets
- **French (fr)**: For Francophone African markets
- **Swahili (sw)**: For East African markets

## Technical Implementation

### Frontend (Next.js)

#### next-i18next Configuration
```typescript
// next-i18next.config.js
module.exports = {
  i18n: {
    defaultLocale: 'en',
    locales: ['en', 'af', 'zu', 'xh'],
    localeDetection: true,
  },
  reloadOnPrerender: process.env.NODE_ENV === 'development',
};
```

#### Page-level Translation
```typescript
// pages/index.tsx
import { useTranslation } from 'next-i18next';
import { serverSideTranslations } from 'next-i18next/serverSideTranslations';

export default function HomePage() {
  const { t } = useTranslation('common');

  return (
    <div>
      <h1>{t('welcome')}</h1>
      <p>{t('description')}</p>
    </div>
  );
}

export async function getStaticProps({ locale }) {
  return {
    props: {
      ...(await serverSideTranslations(locale, ['common'])),
    },
  };
}
```

#### Component Translation
```typescript
// components/ProjectCard.tsx
import { useTranslation } from 'react-i18next';

export function ProjectCard({ project }) {
  const { t } = useTranslation('projects');

  return (
    <div>
      <h3>{project.name}</h3>
      <p>{t('status')}: {t(`statuses.${project.status}`)}</p>
      <button>{t('view_details')}</button>
    </div>
  );
}
```

### Frontend (Angular)

#### Angular i18n Setup
```typescript
// app.module.ts
import { NgModule } from '@angular/core';
import { TranslateModule, TranslateLoader } from '@ngx-translate/core';
import { TranslateHttpLoader } from '@ngx-translate/http-loader';

export function HttpLoaderFactory(http: HttpClient) {
  return new TranslateHttpLoader(http, './assets/i18n/', '.json');
}

@NgModule({
  imports: [
    TranslateModule.forRoot({
      loader: {
        provide: TranslateLoader,
        useFactory: HttpLoaderFactory,
        deps: [HttpClient],
      },
      defaultLanguage: 'en',
    }),
  ],
})
export class AppModule {}
```

#### Component Usage
```typescript
// project-card.component.ts
import { Component } from '@angular/core';
import { TranslateService } from '@ngx-translate/core';

@Component({
  selector: 'app-project-card',
  template: `
    <div>
      <h3>{{ project.name }}</h3>
      <p>{{ 'projects.status' | translate }}: {{ 'projects.statuses.' + project.status | translate }}</p>
      <button>{{ 'common.view_details' | translate }}</button>
    </div>
  `,
})
export class ProjectCardComponent {
  constructor(private translate: TranslateService) {}

  ngOnInit() {
    this.translate.use('af'); // Switch to Afrikaans
  }
}
```

### Backend (NestJS)

#### nestjs-i18n Configuration
```typescript
// app.module.ts
import { I18nModule, I18nJsonParser } from 'nestjs-i18n';

@Module({
  imports: [
    I18nModule.forRoot({
      fallbackLanguage: 'en',
      parser: I18nJsonParser,
      parserOptions: {
        path: join(__dirname, '/i18n/'),
        watch: true,
      },
    }),
  ],
})
export class AppModule {}
```

#### Controller Usage
```typescript
// projects.controller.ts
import { I18n, I18nContext } from 'nestjs-i18n';

@Controller('projects')
export class ProjectsController {
  @Get()
  async findAll(@I18n() i18n: I18nContext) {
    const projects = await this.projectsService.findAll();

    return {
      message: i18n.t('projects.found', {
        args: { count: projects.length },
      }),
      data: projects,
    };
  }

  @Post()
  @UseGuards(JwtAuthGuard)
  async create(
    @Body() createProjectDto: CreateProjectDto,
    @I18n() i18n: I18nContext,
  ) {
    const project = await this.projectsService.create(createProjectDto);

    return {
      message: i18n.t('projects.created'),
      data: project,
    };
  }
}
```

### Translation File Structure

```
public/
├── locales/
│   ├── en/
│   │   ├── common.json
│   │   ├── projects.json
│   │   ├── auth.json
│   │   └── ecommerce.json
│   ├── af/
│   │   ├── common.json
│   │   ├── projects.json
│   │   ├── auth.json
│   │   └── ecommerce.json
│   ├── zu/
│   └── xh/
```

### Translation Files

#### common.json (English)
```json
{
  "welcome": "Welcome to BEIE Nexus",
  "description": "Comprehensive E&I engineering platform",
  "loading": "Loading...",
  "error": "An error occurred",
  "save": "Save",
  "cancel": "Cancel",
  "delete": "Delete",
  "edit": "Edit",
  "view": "View",
  "search": "Search",
  "filter": "Filter",
  "sort": "Sort",
  "export": "Export",
  "import": "Import"
}
```

#### projects.json (English)
```json
{
  "title": "Projects",
  "create": "Create Project",
  "edit": "Edit Project",
  "delete": "Delete Project",
  "status": "Status",
  "statuses": {
    "enquiry": "Enquiry",
    "proposal": "Proposal",
    "contract_signed": "Contract Signed",
    "active": "Active",
    "on_hold": "On Hold",
    "completed": "Completed",
    "cancelled": "Cancelled"
  },
  "found": "Found {{count}} projects",
  "created": "Project created successfully",
  "updated": "Project updated successfully",
  "deleted": "Project deleted successfully"
}
```

#### common.json (Afrikaans)
```json
{
  "welcome": "Welkom by BEIE Nexus",
  "description": "Omvattende E&I ingenieurswese platform",
  "loading": "Laai tans...",
  "error": "ŉ Fout het voorgekom",
  "save": "Stoor",
  "cancel": "Kanselleer",
  "delete": "Skrap",
  "edit": "Wysig",
  "view": "Bekyk",
  "search": "Soek",
  "filter": "Filtreer",
  "sort": "Sorteer",
  "export": "Eksporteer",
  "import": "Importeer"
}
```

## Date and Number Formatting

### South African Locale Settings
```typescript
// Date formatting
const saDateFormat = new Intl.DateTimeFormat('en-ZA', {
  year: 'numeric',
  month: 'short',
  day: '2-digit',
});

// Number formatting (South African Rand)
const zarFormat = new Intl.NumberFormat('en-ZA', {
  style: 'currency',
  currency: 'ZAR',
});

// Example usage
console.log(saDateFormat.format(new Date())); // "27 Apr 2026"
console.log(zarFormat.format(1234.56)); // "R 1 234.56"
```

### Custom Pipes (Angular)
```typescript
// currency.pipe.ts
import { Pipe, PipeTransform } from '@angular/core';

@Pipe({
  name: 'zarCurrency'
})
export class ZarCurrencyPipe implements PipeTransform {
  transform(value: number): string {
    return new Intl.NumberFormat('en-ZA', {
      style: 'currency',
      currency: 'ZAR',
    }).format(value);
  }
}

// date.pipe.ts
import { Pipe, PipeTransform } from '@angular/core';

@Pipe({
  name: 'saDate'
})
export class SaDatePipe implements PipeTransform {
  transform(value: Date | string): string {
    return new Intl.DateTimeFormat('en-ZA', {
      year: 'numeric',
      month: 'short',
      day: '2-digit',
    }).format(new Date(value));
  }
}
```

## Right-to-Left (RTL) Support

### CSS for RTL Languages
```css
/* RTL support */
[dir="rtl"] {
  text-align: right;
}

[dir="rtl"] .flex {
  flex-direction: row-reverse;
}

[dir="rtl"] .mr-4 {
  margin-right: 0;
  margin-left: 1rem;
}
```

### Angular RTL Setup
```typescript
// app.component.ts
import { Component, Inject, LOCALE_ID } from '@angular/core';

@Component({
  selector: 'app-root',
  template: `
    <div [dir]="direction">
      <!-- App content -->
    </div>
  `,
})
export class AppComponent {
  direction = 'ltr';

  constructor(@Inject(LOCALE_ID) private locale: string) {
    // Set direction based on locale
    this.direction = this.isRTL(locale) ? 'rtl' : 'ltr';
  }

  private isRTL(locale: string): boolean {
    const rtlLocales = ['ar', 'he', 'fa'];
    return rtlLocales.some(rtl => locale.startsWith(rtl));
  }
}
```

## Content Management

### Translatable Content Strategy
- **Static Content**: Translated at build time
- **Dynamic Content**: Translated at runtime via API
- **User-Generated Content**: Store in original language with translation metadata

### Translation Workflow
1. **Development**: Use i18n keys in code
2. **Translation**: Professional translators for accuracy
3. **Review**: Native speakers review translations
4. **Testing**: Functional testing in each language
5. **Deployment**: Gradual rollout with feature flags

## SEO and Meta Tags

### Localized Meta Tags
```typescript
// next-i18next for SEO
export async function getServerSideProps({ locale }) {
  return {
    props: {
      ...(await serverSideTranslations(locale, ['common', 'seo'])),
      // SEO props
      title: t('seo:home.title'),
      description: t('seo:home.description'),
    },
  };
}
```

### hreflang Tags
```html
<link rel="alternate" hreflang="en" href="https://beie.co.za/en" />
<link rel="alternate" hreflang="af" href="https://beie.co.za/af" />
<link rel="alternate" hreflang="x-default" href="https://beie.co.za/en" />
```

## Testing Internationalization

### Unit Tests
```typescript
describe('TranslationService', () => {
  it('should translate text correctly', () => {
    const translated = translateService.translate('common.save');
    expect(translated).toBe('Save');
  });

  it('should handle interpolation', () => {
    const translated = translateService.translate('projects.found', {
      count: 5
    });
    expect(translated).toBe('Found 5 projects');
  });
});
```

### E2E Tests
```typescript
describe('Internationalization', () => {
  it('should display content in Afrikaans', () => {
    cy.visit('/af');
    cy.contains('Welkom by BEIE Nexus').should('be.visible');
  });

  it('should persist language preference', () => {
    cy.visit('/');
    cy.get('[data-cy=language-selector]').select('af');
    cy.reload();
    cy.contains('Welkom by BEIE Nexus').should('be.visible');
  });
});
```

## Performance Considerations

### Bundle Splitting
```javascript
// next.config.js
module.exports = {
  i18n: {
    locales: ['en', 'af', 'zu', 'xh'],
    defaultLocale: 'en',
  },
  // Automatic bundle splitting by locale
  experimental: {
    optimizePackageImports: ['next-i18next'],
  },
};
```

### Caching Strategy
- Cache translations by locale
- Use CDN for translation files
- Implement translation file versioning

## Monitoring and Analytics

### Translation Coverage
- Track which strings are translated
- Identify missing translations
- Monitor translation quality

### User Language Preferences
- Track language usage analytics
- A/B test translation improvements
- Monitor user engagement by language

## Maintenance

### Translation Updates
- Regular review of translations
- Update for new features
- Cultural adaptation as needed

### Tooling
- **Phrase**: Translation management platform
- **Crowdin**: Collaborative translation
- **Transifex**: Enterprise translation management

This internationalization setup ensures BEIE Nexus provides a localized experience for South African users and supports future expansion into other African markets.