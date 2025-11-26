#ifdef HAS_WAYLAND

#include <syscall.h>
#include <unistd.h>
#include <sys/mman.h>

#include <wayland-client.h>
#include "../xdg-shell.h"

typedef struct wayland_items {
  struct wl_compositor *compositor;
  struct xdg_wm_base   *wm_base;
  struct wl_surface    *surface;
  bool configured;
} wayland_items;

void noop() { }

void registry_listener_global(void *data, struct wl_registry *registry, uint32_t name, const char *interface, uint32_t version)
{
  wayland_items *items = (wayland_items *)data;
  if (strEQ(interface, wl_compositor_interface.name))
  {
    items->compositor = wl_registry_bind(registry, name, &wl_compositor_interface, 1);
    return;
  }
  if (strEQ(interface, xdg_wm_base_interface.name))
  {
    items->wm_base = wl_registry_bind(registry, name, &xdg_wm_base_interface, 1);
    return;
  }
}

static const struct wl_registry_listener registry_listener = {
  .global = registry_listener_global,
  .global_remove = noop,
};

static void xdg_s_listener_configure(void *data, struct xdg_surface *xdg_surface, uint32_t serial)
{
  wayland_items *items = (wayland_items *)data;
  xdg_surface_ack_configure(xdg_surface, serial);

  if (items->configured)
  {
    wl_surface_commit(items->surface);
  }

  items->configured = true;
}

static const struct xdg_surface_listener xdg_s_listener = {
  .configure = xdg_s_listener_configure,
};

static const struct xdg_toplevel_listener xdg_tl_listener = {
  .configure = noop,
  .close = noop,
};

bool wayland_window(WGPUSurfaceSourceWaylandSurface *result, int xw, int yh)
{
  Zero((void*)result, 1, WGPUSurfaceSourceWaylandSurface);
  xw = xw ? xw : 640;
  yh = yh ? yh : 360;

  struct wl_display *display = wl_display_connect(NULL);
  if (!display)
  {
    return false;
  }

  struct wl_registry *registry = wl_display_get_registry(display);
  if ( !registry )
  {
    wl_display_disconnect(display);
    return false;
  }

  wayland_items *items = NULL;
  Newxz(items, 1, wayland_items);

  wl_registry_add_listener(registry, &registry_listener, items);
  wl_display_roundtrip(display);

  if ( !items->compositor || !items->wm_base )
  {
    wl_registry_destroy(registry);
    if ( items->compositor )
    {
      wl_compositor_destroy(items->compositor);
    }
    if ( items->wm_base )
    {
      xdg_wm_base_destroy( items->wm_base );
    }
    wl_display_disconnect(display);
    return false;
  }

  items->surface = wl_compositor_create_surface(items->compositor);

  struct xdg_surface *xdgs = xdg_wm_base_get_xdg_surface(items->wm_base, items->surface);
  struct xdg_toplevel *xdg_toplevel = xdg_surface_get_toplevel(xdgs);

  xdg_toplevel_set_title(xdg_toplevel, "WebGPU::Direct example");
  xdg_toplevel_set_app_id(xdg_toplevel, "WebGPU::Direct example");

  xdg_surface_add_listener(xdgs, &xdg_s_listener, items);
  xdg_toplevel_add_listener(xdg_toplevel, &xdg_tl_listener, items);

  wl_surface_commit(items->surface);
  wl_display_roundtrip(display);
  wl_surface_commit(items->surface);

  result->chain.sType = WGPUSType_SurfaceSourceWaylandSurface;
  result->display = display;
  result->surface = items->surface;

  return true;
}

#endif
