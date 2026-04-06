package com.yaonet.products.reflectiondemo;

import java.lang.reflect.Field;
import java.lang.reflect.Method;

public class ReflectionDemoRunner {

    public static void main(String[] args) throws Exception {
        Class<?> targetClass = MiniProductController.class;

        System.out.println("1. Load class metadata");
        System.out.println("   Class name: " + targetClass.getName());

        if (targetClass.isAnnotationPresent(DemoComponent.class)) {
            DemoComponent component = targetClass.getAnnotation(DemoComponent.class);
            System.out.println("2. Found @DemoComponent value = " + component.value());
        }

        Object controller = targetClass.getDeclaredConstructor().newInstance();
        System.out.println("3. Created object reflectively: " + controller.getClass().getSimpleName());

        for (Field field : targetClass.getDeclaredFields()) {
            if (field.isAnnotationPresent(DemoValue.class)) {
                DemoValue config = field.getAnnotation(DemoValue.class);
                field.setAccessible(true);
                field.set(controller, config.value());
                System.out.println("4. Injected field '" + field.getName() + "' = " + config.value());
            }
        }

        for (Method method : targetClass.getDeclaredMethods()) {
            if (method.isAnnotationPresent(DemoGetMapping.class)) {
                DemoGetMapping mapping = method.getAnnotation(DemoGetMapping.class);
                Object result = method.invoke(controller);
                System.out.println("5. Route " + mapping.value() + " -> method " + method.getName());
                System.out.println("   Invocation result: " + result);
            }
        }
    }
}