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
-- Data for Name: User; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."User" ("userId", "userEmail", "userName", "userPassword", "userPhoneNumber", "userBonusAccount", "userInterfaceLanguage", "userNotification", "userPhoto") FROM stdin;
\.


--
-- Data for Name: Basket; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Basket" ("basketId", "userBasketId") FROM stdin;
\.


--
-- Data for Name: Order; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Order" ("orderId", "orderBasketId", "OrderDate") FROM stdin;
\.


--
-- Data for Name: Delivery; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Delivery" ("deliveryId", "deliveryType", "deliveryAdress", "deliveryCity", "deliveryPrice", "deliveryOrderId") FROM stdin;
\.


--
-- Data for Name: Product; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Product" ("productId", "productName", "productDescription", "productBrand", "basketProductId") FROM stdin;
\.


--
-- Data for Name: Shop; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Shop" ("shopId", "shopAdress", "shopOpen", "shopClose", "shopType") FROM stdin;
\.


--
-- Data for Name: ProductShop; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."ProductShop" ("ProductShopId", "shopID", "productID", "productQuantity") FROM stdin;
\.


--
-- Data for Name: UsersProductQuantity; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."UsersProductQuantity" ("usersProductQuantityId", "productQuantity", "productId", "userBasketId") FROM stdin;
\.


--
-- Data for Name: _prisma_migrations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public._prisma_migrations (id, checksum, finished_at, migration_name, logs, rolled_back_at, started_at, applied_steps_count) FROM stdin;
5033a3e6-4c70-4178-998e-01332b567202	27970dcdcfd4080f3e0566713a136e945d34ae05940aa55f8c6721bdbc33b307	2024-05-16 07:56:46.269573+00	20240516075646_init	\N	\N	2024-05-16 07:56:46.172238+00	1
\.


--
-- PostgreSQL database dump complete
--

