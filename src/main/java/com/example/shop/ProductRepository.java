package com.example.shop;

import org.springframework.data.jpa.repository.JpaRepository;

/** Доступ к таблице products в PostgreSQL. */
public interface ProductRepository extends JpaRepository<Product, Long> {
}
