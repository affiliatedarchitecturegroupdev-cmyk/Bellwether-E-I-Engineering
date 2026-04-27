import { Controller, Get, UseGuards } from '@nestjs/common';
import { AppService } from './app.service';
import { SupabaseAuthGuard } from './auth/auth.guard';

@Controller()
export class AppController {
  constructor(private readonly appService: AppService) {}

  @Get()
  getHello(): string {
    return this.appService.getHello();
  }

  @Get('health')
  getHealth(): object {
    return { status: 'ok', timestamp: new Date().toISOString() };
  }

  @UseGuards(SupabaseAuthGuard)
  @Get('protected')
  getProtected(): object {
    return { message: 'This is a protected route', timestamp: new Date().toISOString() };
  }
}