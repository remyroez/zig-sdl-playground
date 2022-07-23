const std = @import("std");

const c = @cImport({
    @cInclude("SDL2/SDL.h");
    @cInclude("SDL2/SDL_image.h");
});

pub fn main() anyerror!void {
    if (c.SDL_Init(c.SDL_INIT_VIDEO) != 0) {
        c.SDL_Log("Unable to initialize SDL: %s", c.SDL_GetError());
        return error.FailedToInitSDL;
    }
    defer c.SDL_Quit();

    var window: ?*c.SDL_Window = null;
    var renderer: ?*c.SDL_Renderer = null;
    if (c.SDL_CreateWindowAndRenderer(
        640, 480,
        c.SDL_WINDOW_SHOWN | c.SDL_WINDOW_ALLOW_HIGHDPI,
        &window, &renderer) != 0) {
        c.SDL_Log("Unable to create window and renderer: %s", c.SDL_GetError());
        return error.FailedToInitWindowAndRenderer;
    }
    defer c.SDL_DestroyWindow(window);

    const image_file = @embedFile("zero.png");
    const rw = c.SDL_RWFromConstMem(
        @ptrCast(*const anyopaque, &image_file[0]),
        @intCast(c_int, image_file.len),
    ) orelse {
        c.SDL_Log("Unable to get RWFromConstMem: %s", c.SDL_GetError());
        return error.SDLInitializationFailed;
    };
    defer std.debug.assert(c.SDL_RWclose(rw) == 0);

    _ = c.IMG_Init(c.IMG_INIT_PNG);
    defer c.IMG_Quit();

    const texture = c.IMG_LoadTexture_RW(renderer, rw, 0) orelse {
        c.SDL_Log("Unable to load texture: %s", c.IMG_GetError());
        return error.SDLInitializationFailed;
    };
    defer c.SDL_DestroyTexture(texture);

    var width: i32 = 0;
    var height: i32 = 0;
    _ = c.SDL_QueryTexture(texture, null, null, &width, &height);

    const rect: c.SDL_Rect = .{ .w = width, .h = height, .x = 0, .y = 0 };

    mainloop: while(true) {
        var event: c.SDL_Event = undefined;
        while (c.SDL_PollEvent(&event) != 0) {
            switch (event.type) {
                c.SDL_QUIT => {
                    break :mainloop;
                },
                else => {}
            }
        }

        _ = c.SDL_SetRenderDrawColor(renderer, 0xFF, 0x7F, 0x00, 0xFF);
        _ = c.SDL_RenderClear(renderer);
        _ = c.SDL_RenderCopy(renderer, texture, null, &rect);
        _ = c.SDL_RenderPresent(renderer);

        c.SDL_Delay(1000 / 60);
    }

    // Note that info level log messages are by default printed only in Debug
    // and ReleaseSafe build modes.
    std.log.info("May {s} be with you", .{"the SDL"});
}

test "basic test" {
    try std.testing.expectEqual(10, 3 + 7);
}
