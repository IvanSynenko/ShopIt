--
-- PostgreSQL database dump
--

-- Dumped from database version 16.0 (Debian 16.0-1.pgdg120+1)
-- Dumped by pg_dump version 16.0 (Debian 16.0-1.pgdg120+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: postgres
--

-- *not* creating schema, since initdb creates it


ALTER SCHEMA public OWNER TO postgres;

--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON SCHEMA public IS '';


--
-- Name: Role; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public."Role" AS ENUM (
    'ADMIN',
    'USER',
    'MODERATOR'
);


ALTER TYPE public."Role" OWNER TO postgres;

--
-- Name: ShopType; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public."ShopType" AS ENUM (
    'WAREHOUSE',
    'FOODSTORE',
    'SUPERMARKET',
    'PICKUP'
);


ALTER TYPE public."ShopType" OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: Basket; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Basket" (
    "basketId" text NOT NULL,
    "userBasketId" text NOT NULL
);


ALTER TABLE public."Basket" OWNER TO postgres;

--
-- Name: Delivery; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Delivery" (
    "deliveryId" text NOT NULL,
    "deliveryType" boolean DEFAULT false NOT NULL,
    "deliveryAdress" text,
    "deliveryCity" text,
    "deliveryPrice" text NOT NULL,
    "deliveryOrderId" text NOT NULL
);


ALTER TABLE public."Delivery" OWNER TO postgres;

--
-- Name: Order; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Order" (
    "orderId" text NOT NULL,
    "orderBasketId" text NOT NULL,
    "OrderDate" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public."Order" OWNER TO postgres;

--
-- Name: Product; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Product" (
    "productId" text NOT NULL,
    "productName" text NOT NULL,
    "productDescription" text,
    "productBrand" text NOT NULL,
    "basketProductId" text NOT NULL
);


ALTER TABLE public."Product" OWNER TO postgres;

--
-- Name: ProductShop; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."ProductShop" (
    "ProductShopId" text NOT NULL,
    "shopID" text NOT NULL,
    "productID" text NOT NULL,
    "productQuantity" integer NOT NULL
);


ALTER TABLE public."ProductShop" OWNER TO postgres;

--
-- Name: Shop; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Shop" (
    "shopId" text NOT NULL,
    "shopAdress" text NOT NULL,
    "shopOpen" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "shopClose" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "shopType" public."ShopType" DEFAULT 'SUPERMARKET'::public."ShopType" NOT NULL
);


ALTER TABLE public."Shop" OWNER TO postgres;

--
-- Name: User; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."User" (
    "userId" text NOT NULL,
    "userEmail" text NOT NULL,
    "userName" text,
    "userPassword" text NOT NULL,
    "userPhoneNumber" text,
    "userBonusAccount" text,
    "userInterfaceLanguage" boolean DEFAULT false NOT NULL,
    "userNotification" boolean DEFAULT false NOT NULL,
    "userPhoto" text
);


ALTER TABLE public."User" OWNER TO postgres;

--
-- Name: UsersProductQuantity; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."UsersProductQuantity" (
    "usersProductQuantityId" text NOT NULL,
    "productQuantity" integer NOT NULL,
    "productId" text NOT NULL,
    "userBasketId" text NOT NULL
);


ALTER TABLE public."UsersProductQuantity" OWNER TO postgres;

--
-- Name: _prisma_migrations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public._prisma_migrations (
    id character varying(36) NOT NULL,
    checksum character varying(64) NOT NULL,
    finished_at timestamp with time zone,
    migration_name character varying(255) NOT NULL,
    logs text,
    rolled_back_at timestamp with time zone,
    started_at timestamp with time zone DEFAULT now() NOT NULL,
    applied_steps_count integer DEFAULT 0 NOT NULL
);


ALTER TABLE public._prisma_migrations OWNER TO postgres;

--
-- Name: Basket Basket_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Basket"
    ADD CONSTRAINT "Basket_pkey" PRIMARY KEY ("basketId");


--
-- Name: Delivery Delivery_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Delivery"
    ADD CONSTRAINT "Delivery_pkey" PRIMARY KEY ("deliveryId");


--
-- Name: Order Order_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Order"
    ADD CONSTRAINT "Order_pkey" PRIMARY KEY ("orderId");


--
-- Name: ProductShop ProductShop_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ProductShop"
    ADD CONSTRAINT "ProductShop_pkey" PRIMARY KEY ("ProductShopId");


--
-- Name: Product Product_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Product"
    ADD CONSTRAINT "Product_pkey" PRIMARY KEY ("productId");


--
-- Name: Shop Shop_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Shop"
    ADD CONSTRAINT "Shop_pkey" PRIMARY KEY ("shopId");


--
-- Name: User User_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."User"
    ADD CONSTRAINT "User_pkey" PRIMARY KEY ("userId");


--
-- Name: UsersProductQuantity UsersProductQuantity_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."UsersProductQuantity"
    ADD CONSTRAINT "UsersProductQuantity_pkey" PRIMARY KEY ("usersProductQuantityId");


--
-- Name: _prisma_migrations _prisma_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public._prisma_migrations
    ADD CONSTRAINT _prisma_migrations_pkey PRIMARY KEY (id);


--
-- Name: Basket_userBasketId_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "Basket_userBasketId_key" ON public."Basket" USING btree ("userBasketId");


--
-- Name: Delivery_deliveryOrderId_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "Delivery_deliveryOrderId_key" ON public."Delivery" USING btree ("deliveryOrderId");


--
-- Name: Product_basketProductId_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "Product_basketProductId_key" ON public."Product" USING btree ("basketProductId");


--
-- Name: User_userEmail_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "User_userEmail_key" ON public."User" USING btree ("userEmail");


--
-- Name: Basket Basket_userBasketId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Basket"
    ADD CONSTRAINT "Basket_userBasketId_fkey" FOREIGN KEY ("userBasketId") REFERENCES public."User"("userId") ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: Delivery Delivery_deliveryOrderId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Delivery"
    ADD CONSTRAINT "Delivery_deliveryOrderId_fkey" FOREIGN KEY ("deliveryOrderId") REFERENCES public."Order"("orderId") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: Order Order_orderBasketId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Order"
    ADD CONSTRAINT "Order_orderBasketId_fkey" FOREIGN KEY ("orderBasketId") REFERENCES public."Basket"("basketId") ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: ProductShop ProductShop_productID_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ProductShop"
    ADD CONSTRAINT "ProductShop_productID_fkey" FOREIGN KEY ("productID") REFERENCES public."Product"("productId") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: ProductShop ProductShop_shopID_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ProductShop"
    ADD CONSTRAINT "ProductShop_shopID_fkey" FOREIGN KEY ("shopID") REFERENCES public."Shop"("shopId") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: Product Product_basketProductId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Product"
    ADD CONSTRAINT "Product_basketProductId_fkey" FOREIGN KEY ("basketProductId") REFERENCES public."Basket"("basketId") ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: UsersProductQuantity UsersProductQuantity_productId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."UsersProductQuantity"
    ADD CONSTRAINT "UsersProductQuantity_productId_fkey" FOREIGN KEY ("productId") REFERENCES public."Product"("productId") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: UsersProductQuantity UsersProductQuantity_userBasketId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."UsersProductQuantity"
    ADD CONSTRAINT "UsersProductQuantity_userBasketId_fkey" FOREIGN KEY ("userBasketId") REFERENCES public."Basket"("basketId") ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE USAGE ON SCHEMA public FROM PUBLIC;


--
-- PostgreSQL database dump complete
--

