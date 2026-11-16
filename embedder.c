/* Minimal Flutter software-rendering host for the webOS 6 compatibility test. */
#include <SDL.h>
#include <inttypes.h>
#include <pthread.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "embedder.h"

enum { width = 640, height = 360 };

struct host {
  pthread_mutex_t mutex;
  uint32_t pixels[width * height];
  bool fresh;
  unsigned confirmations;
  FlutterEngine engine;
};

static bool present(void *context, const void *allocation, size_t row_bytes,
                    size_t rows) {
  struct host *host = context;
  if (rows != height || row_bytes < sizeof(host->pixels[0]) * width) return false;
  pthread_mutex_lock(&host->mutex);
  for (size_t row = 0; row < height; row++) {
    memcpy(host->pixels + row * width, (const uint8_t *)allocation + row * row_bytes,
           sizeof(host->pixels[0]) * width);
  }
  host->fresh = true;
  pthread_mutex_unlock(&host->mutex);
  return true;
}

static const SDL_Keycode keys[] = {
    SDLK_LEFT, SDLK_RIGHT, SDLK_UP, SDLK_DOWN, SDLK_RETURN,
};

static void key_result(const uint8_t *data, size_t size, void *context) {
  struct host *host = context;
  if (size == 2 && data[0] == 3 && data[1] == 1) host->confirmations++;
}

static void log_message(const char *tag, const char *message, void *context) {
  (void)context;
  fprintf(stderr, "%s: %s\n", tag, message);
}

static void platform_message(const FlutterPlatformMessage *message, void *context) {
  struct host *host = context;
  if (host->engine && message->response_handle) {
    FlutterEngineSendPlatformMessageResponse(host->engine, message->response_handle, NULL, 0);
  }
}

static void send_key(struct host *host, const SDL_KeyboardEvent *event) {
  if (event->type != SDL_KEYDOWN) return;
  for (size_t i = 0; i < sizeof(keys) / sizeof(keys[0]); i++) {
    if (event->keysym.sym != keys[i]) continue;
    const uint8_t code = (uint8_t)i;
    FlutterPlatformMessageResponseHandle *response = NULL;
    if (FlutterPlatformMessageCreateResponseHandle(host->engine, key_result,
                                                         host, &response) != kSuccess) {
      fputs("Could not create remote event response handle\n", stderr);
      return;
    }
    const FlutterPlatformMessage message = {
        .struct_size = sizeof(message),
        .channel = "com.aleks.webos6/remote",
        .message = &code,
        .message_size = sizeof(code),
        .response_handle = response,
    };
    const FlutterEngineResult result = FlutterEngineSendPlatformMessage(host->engine, &message);
    FlutterPlatformMessageReleaseResponseHandle(host->engine, response);
    if (result != kSuccess) fputs("Could not send remote event\n", stderr);
    return;
  }
}

static bool queue_test_keys(void) {
  const SDL_Keycode sequence[] = {SDLK_RIGHT, SDLK_DOWN, SDLK_RETURN};
  for (size_t i = 0; i < sizeof(sequence) / sizeof(sequence[0]); i++) {
    SDL_Event event = {.type = SDL_KEYDOWN};
    event.key.state = SDL_PRESSED;
    event.key.keysym.sym = sequence[i];
    if (SDL_PushEvent(&event) != 1) return false;
    event.type = SDL_KEYUP;
    event.key.state = SDL_RELEASED;
    if (SDL_PushEvent(&event) != 1) return false;
  }
  return true;
}

static bool run_screen(struct host *host, SDL_Renderer *renderer,
                       SDL_Texture *texture, bool smoke, bool self_test) {
  bool running = true;
  bool first_frame = true;
  const Uint32 start = SDL_GetTicks();
  Uint32 frame_time = 0;
  bool test_keys_sent = false;
  while (running && SDL_GetTicks() - start < (smoke ? 15000u : 45000u)) {
    __FlutterEngineFlushPendingTasksNow();
    SDL_Event event;
    while (SDL_PollEvent(&event)) {
      if (event.type == SDL_QUIT ||
          (event.type == SDL_KEYDOWN &&
           (event.key.keysym.sym == SDLK_ESCAPE || event.key.keysym.sym == SDLK_AC_BACK))) {
        running = false;
      } else if (event.type == SDL_KEYDOWN || event.type == SDL_KEYUP) {
        send_key(host, &event.key);
      }
    }

    pthread_mutex_lock(&host->mutex);
    const bool fresh = host->fresh;
    const int result = fresh && texture ? SDL_UpdateTexture(texture, NULL, host->pixels,
                                                width * sizeof(host->pixels[0])) : 0;
    host->fresh = false;
    pthread_mutex_unlock(&host->mutex);
    if (fresh && (!renderer ||
        (result == 0 && SDL_RenderCopy(renderer, texture, NULL, NULL) == 0))) {
      if (renderer) SDL_RenderPresent(renderer);
      if (first_frame) {
        puts(renderer ? "FLUTTER_FRAME_PRESENTED" : "FLUTTER_FRAME_RENDERED");
        fflush(stdout);
        first_frame = false;
        if (smoke) return true;
        frame_time = SDL_GetTicks();
      }
    }
    if (self_test && !first_frame) {
      const Uint32 since_frame = SDL_GetTicks() - frame_time;
      if (since_frame >= 750 && !test_keys_sent) {
        if (!queue_test_keys()) return false;
        test_keys_sent = true;
      }
      if (since_frame >= 2000) {
        printf("FLUTTER_CONFIRMED_CARD_FOUR=%u\n", host->confirmations);
        return host->confirmations == 1;
      }
    }
    SDL_Delay(8);
  }
  return !first_frame && !self_test;
}

int main(int argc, char **argv) {
  const bool smoke = argc == 5 && strcmp(argv[4], "--smoke") == 0;
  const bool headless = argc == 5 && strcmp(argv[4], "--headless") == 0;
  const bool self_test = argc == 5 && strcmp(argv[4], "--self-test") == 0;
  if (argc < 4 || argc > 5 || (argc == 5 && !smoke && !headless && !self_test)) {
    fprintf(stderr, "Usage: %s ASSETS ICU APP_ELF [--smoke|--headless|--self-test]\n", argv[0]);
    return 2;
  }

  if (SDL_Init(headless ? SDL_INIT_TIMER : SDL_INIT_VIDEO) != 0) {
    fprintf(stderr, "SDL_Init: %s\n", SDL_GetError());
    return 1;
  }
  SDL_Window *window = headless ? NULL : SDL_CreateWindow("AlekS Flutter", SDL_WINDOWPOS_CENTERED,
                                        SDL_WINDOWPOS_CENTERED, width, height,
                                        SDL_WINDOW_SHOWN);
  SDL_Renderer *renderer = window ? SDL_CreateRenderer(window, -1, SDL_RENDERER_SOFTWARE) : NULL;
  SDL_Texture *texture = renderer ? SDL_CreateTexture(renderer, SDL_PIXELFORMAT_BGRA32,
                                                       SDL_TEXTUREACCESS_STREAMING,
                                                       width, height) : NULL;
  FlutterEngineAOTData aot_data = NULL;
  FlutterEngine engine = NULL;
  static struct host host = {.mutex = PTHREAD_MUTEX_INITIALIZER};
  int status = 1;
  if (!headless && !texture) {
    fprintf(stderr, "SDL window/renderer: %s\n", SDL_GetError());
    goto done;
  }

  const FlutterEngineAOTDataSource source = {
      .type = kFlutterEngineAOTDataSourceTypeElfPath,
      .elf_path = argv[3],
  };
  if (!FlutterEngineRunsAOTCompiledDartCode() ||
      FlutterEngineCreateAOTData(&source, &aot_data) != kSuccess) {
    fputs("Flutter AOT initialization failed\n", stderr);
    goto done;
  }

  const FlutterRendererConfig config = {
      .type = kSoftware,
      .software = {.struct_size = sizeof(FlutterSoftwareRendererConfig),
                   .surface_present_callback = present},
  };
  const char *engine_argv[] = {"aleks-flutter", "--enable-impeller=false"};
  const FlutterProjectArgs project = {
      .struct_size = sizeof(project),
      .assets_path = argv[1],
      .icu_data_path = argv[2],
      .command_line_argc = sizeof(engine_argv) / sizeof(engine_argv[0]),
      .command_line_argv = engine_argv,
      .aot_data = aot_data,
      .log_message_callback = log_message,
      .platform_message_callback = platform_message,
  };
  if (FlutterEngineRun(FLUTTER_ENGINE_VERSION, &config, &project, &host, &engine) != kSuccess) {
    fputs("FlutterEngineRun failed\n", stderr);
    goto done;
  }
  host.engine = engine;
  const FlutterWindowMetricsEvent metrics = {
      .struct_size = sizeof(metrics),
      .width = width, .height = height, .pixel_ratio = 1.0,
  };
  if (FlutterEngineSendWindowMetricsEvent(engine, &metrics) != kSuccess) goto done;
  if (run_screen(&host, renderer, texture, smoke || headless, self_test)) status = 0;
  else fputs("Flutter smoke test did not complete\n", stderr);

done:
  if (engine) FlutterEngineShutdown(engine);
  if (aot_data) FlutterEngineCollectAOTData(aot_data);
  if (texture) SDL_DestroyTexture(texture);
  if (renderer) SDL_DestroyRenderer(renderer);
  if (window) SDL_DestroyWindow(window);
  SDL_Quit();
  return status;
}
