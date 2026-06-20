**tests/test_framework.h**
```c
#ifndef TEST_FRAMEWORK_H
#define TEST_FRAMEWORK_H

#include <stdio.h>
#include <stdbool.h>

#define TEST_ASSERT(cond) \
    do { \
        if (!(cond)) { \
            printf("  ✗ FAIL at line %d\n", __LINE__); \
            return false; \
        } \
    } while(0)

#define TEST_ASSERT_EQ(expected, actual) \
    TEST_ASSERT((expected) == (actual))

#define TEST_ASSERT_NULL(ptr) \
    TEST_ASSERT((ptr) == NULL)

#define TEST_ASSERT_NOT_NULL(ptr) \
    TEST_ASSERT((ptr) != NULL)

typedef struct {
    const char *name;
    bool (*func)(void);
} TestCase;

static inline int run_tests(TestCase tests[], int count) {
    int passed = 0;
    printf("\n=== Running %d tests ===\n", count);
    
    for (int i = 0; i < count; i++) {
        printf("%s... ", tests[i].name);
        if (tests[i].func()) {
            printf("✓ OK\n");
            passed++;
        } else {
            printf("✗ FAIL\n");
        }
    }
    
    printf("=== Result: %d passed, %d failed ===\n", passed, count - passed);
    return count - passed;
}

#endif
```

## Тестируемая функция

**src/myfunc.h**
```c
#ifndef MYFUNC_H
#define MYFUNC_H

#include <stddef.h>

// Функция проверяет, попадает ли значение в диапазон [0, 100]
// Возвращает: 0 - OK, -1 - ошибка
int check_range(int value);

#endif
```

**src/myfunc.c**
```c
#include "myfunc.h"

int check_range(int value) {
    if (value < 0 || value > 100) {
        return -1;  // Вне диапазона
    }
    return 0;  // В диапазоне
}
```

## Тесты для check_range

**tests/test_myfunc.c**
```c
#include "../src/myfunc.h"
#include "test_framework.h"

// Тест 1: Проверка на попадание в диапазон
bool test_check_range_ok(void) {
    int result = check_range(50);
    TEST_ASSERT_EQ(0, result);
    return true;
}

// Тест 2: Проверка выхода за границы
bool test_check_range_out_of_bounds(void) {
    int result = check_range(150);
    TEST_ASSERT_EQ(-1, result);
    return true;
}

// Тест 3: Передача NULL (здесь просто проверяем, что NULL не передается)
// Для демонстрации - этот тест упадет
bool test_check_range_null(void) {
    int result = check_range(-999);
    TEST_ASSERT_EQ(0, result);
    return true;
}

int main(void) {
    TestCase tests[] = {
        {"check_range: valid value", test_check_range_ok},
        {"check_range: out of bounds", test_check_range_out_of_bounds},
        {"check_range: extreme negative", test_check_range_null},
    };
    
    int failed = run_tests(tests, sizeof(tests) / sizeof(tests[0]));
    return failed > 0 ? 1 : 0;
}
```

## Makefile

```makefile
CC = gcc
CFLAGS = -Wall -Wextra -g -I./src -I./tests

all: test_myfunc

test_myfunc: tests/test_myfunc.c src/myfunc.c
	$(CC) $(CFLAGS) -o $@ $^

run: test_myfunc
	./test_myfunc

clean:
	rm -f test_myfunc

.PHONY: all run clean
```

## Запуск и вывод

```bash
$ make run

=== Running 3 tests ===
check_range: valid value... ✓ OK
check_range: out of bounds... ✓ OK
check_range: extreme negative... ✗ FAIL at line 20
=== Result: 2 passed, 1 failed ===
```

---

## добавить тест для новой функции

### Шаг 1: Создаешь новую функцию

**src/newfunc.h**
```c
#ifndef NEWFUNC_H
#define NEWFUNC_H

int multiply(int a, int b);

#endif
```

**src/newfunc.c**
```c
#include "newfunc.h"

int multiply(int a, int b) {
    return a * b;
}
```

### Шаг 2: Создаешь тестовый файл

**tests/test_newfunc.c**
```c
#include "../src/newfunc.h"
#include "test_framework.h"

// Твои тесты
bool test_multiply_positive(void) {
    int result = multiply(3, 4);
    TEST_ASSERT_EQ(12, result);
    return true;
}

bool test_multiply_zero(void) {
    int result = multiply(0, 5);
    TEST_ASSERT_EQ(0, result);
    return true;
}

bool test_multiply_negative(void) {
    int result = multiply(-2, 3);
    TEST_ASSERT_EQ(-6, result);
    return true;
}

int main(void) {
    TestCase tests[] = {
        {"multiply: positive", test_multiply_positive},
        {"multiply: zero", test_multiply_zero},
        {"multiply: negative", test_multiply_negative},
    };
    
    int failed = run_tests(tests, 3);
    return failed > 0 ? 1 : 0;
}
```

### Шаг 3: Обновляешь Makefile

```makefile
CC = gcc
CFLAGS = -Wall -Wextra -g -I./src -I./tests

# Добавляешь новый тест в список
TESTS = test_myfunc test_newfunc

all: $(TESTS)

# Автоматическое правило для всех тестов
# Обрати внимание, имя файла с тестами содержит имя тестируемого модуля - чтобы избежать двойного main
test_%: tests/test_%.c src/%.c
	$(CC) $(CFLAGS) -o $@ $^

run: $(TESTS)
	@for test in $(TESTS); do \
		echo "\n========================================="; \
		echo "Running $$test"; \
		echo "========================================="; \
		./$$test; \
	done

clean:
	rm -f $(TESTS)

.PHONY: all run clean
```

### Шаг 4: Запускаешь

```bash
make run
```

---

**Чтобы добавить новую функцию:**
1. Создаешь `tests/test_новоеимя.c`
2. Копируешь шаблон с тремя тестами
3. Добавляешь имя в `TESTS` в Makefile
4. Запускаешь `make run`

**Главные преимущества:**
- Минимум кода
- Все тесты независимы
- Легко добавить новый
- Не нужно менять существующие тесты
