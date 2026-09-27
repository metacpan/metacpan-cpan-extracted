import { DurableObject } from "cloudflare:workers";
import { createDurableObjectClass } from "./durable-object-runtime.js";

export function createWebDyneDurableObject(options) {
  return createDurableObjectClass({ ...options, DurableObject });
}
