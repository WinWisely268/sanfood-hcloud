CREATE TYPE public.product_type AS ENUM (
    'reguler',
    'musiman'
);
CREATE FUNCTION public.exec(text) RETURNS text
    LANGUAGE plpgsql
    AS $_$ BEGIN EXECUTE $1; RETURN $1; END; $_$;
CREATE FUNCTION public.get_film_count(len_from integer, len_to integer) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
begin
   return true;
end;
$$;
CREATE TABLE public.text_result (
    result text
);
CREATE FUNCTION public.get_session_role(hasura_session json) RETURNS SETOF public.text_result
    LANGUAGE sql STABLE
    AS $$
    SELECT q.* FROM (VALUES (hasura_session ->> 'x-hasura-role')) q
$$;
CREATE TABLE public.product_categories (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name text NOT NULL
);
CREATE FUNCTION public.search_product_categories(search text) RETURNS SETOF public.product_categories
    LANGUAGE sql STABLE
    AS $$
SELECT
  *
FROM
  product_categories
WHERE
  search <% name
ORDER BY
  similarity(search, name) DESC
LIMIT
  10 $$;
CREATE TABLE public.products (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name text NOT NULL,
    product_code text NOT NULL,
    variant text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    product_type public.product_type DEFAULT 'reguler'::public.product_type NOT NULL,
    expiry_interval interval,
    srp double precision,
    is_active boolean DEFAULT true NOT NULL,
    category_id uuid,
    packaging_id uuid
);
COMMENT ON TABLE public.products IS 'product table';
CREATE FUNCTION public.search_products(search text) RETURNS SETOF public.products
    LANGUAGE sql STABLE
    AS $$
    SELECT *
    FROM products
    WHERE
        search<% (name || ' ' || product_code)
    ORDER BY
        similarity(search, (name || ' ' || product_code)) DESC
    LIMIT 10
$$;
CREATE TABLE public.accounts (
    user_id uuid NOT NULL,
    role text NOT NULL,
    email text NOT NULL,
    last_login timestamp with time zone DEFAULT now()
);
CREATE TABLE public.attendance_config (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    half_work_hours interval DEFAULT '03:00:00'::interval NOT NULL,
    full_work_hours interval DEFAULT '08:00:00'::interval NOT NULL
);
CREATE TABLE public.attendance_records (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    account_id uuid NOT NULL,
    on_going_home text NOT NULL,
    on_going_work text NOT NULL,
    on_going_home_timestamp integer NOT NULL,
    on_going_work_timestamp integer NOT NULL,
    created timestamp with time zone DEFAULT now() NOT NULL,
    updated timestamp with time zone NOT NULL,
    on_going_home_loc point,
    on_going_work_loc point
);
CREATE TABLE public.branches (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name text NOT NULL,
    address text NOT NULL,
    city text NOT NULL,
    province text NOT NULL,
    area_id uuid NOT NULL,
    created_date timestamp without time zone NOT NULL,
    updated_date timestamp without time zone NOT NULL,
    distributor_id uuid NOT NULL,
    location_id uuid NOT NULL
);
CREATE TABLE public.contracts (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    start_date date NOT NULL,
    renewal_duration date NOT NULL,
    renewal_date date NOT NULL
);
CREATE TABLE public.distributors (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name text NOT NULL,
    start_date date NOT NULL,
    end_date date,
    hq_address text NOT NULL,
    hq_city text NOT NULL,
    hq_province text NOT NULL,
    area_id uuid NOT NULL,
    is_enabled boolean NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    is_assignable boolean DEFAULT true NOT NULL
);
CREATE TABLE public.distro_store_assignments (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    branch_id uuid,
    mate_store_id uuid,
    user_id uuid NOT NULL
);
CREATE TABLE public.inventories (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    product_id uuid NOT NULL,
    branch_id uuid NOT NULL,
    mate_store_id uuid NOT NULL,
    qty double precision DEFAULT 0.00 NOT NULL,
    expiry_date date NOT NULL,
    arrival_date date NOT NULL
);
CREATE TABLE public.locations (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    geo_loc public.geometry(Point,4326),
    name text
);
CREATE TABLE public.marketing_regions (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    region_code text NOT NULL,
    notes text NOT NULL
);
CREATE TABLE public.mate_stores (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name text NOT NULL,
    start_date date NOT NULL,
    end_date date,
    address text NOT NULL,
    city text NOT NULL,
    province text NOT NULL,
    location_id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    is_enabled boolean DEFAULT true NOT NULL,
    supplier_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone
);
CREATE TABLE public.product_packagings (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    unit text NOT NULL,
    notes text NOT NULL
);
CREATE TABLE public.product_pictures (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    picture text,
    expiry interval NOT NULL,
    product_id uuid NOT NULL
);
CREATE TABLE public.user_pictures (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    account_id uuid NOT NULL,
    picture_url text
);
CREATE TABLE public.user_profiles (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    devices jsonb
);
CREATE TABLE public.users (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    account_id uuid NOT NULL,
    address text NOT NULL,
    government_id text NOT NULL,
    birth_date date NOT NULL,
    name text NOT NULL,
    locked boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now(),
    last_modified timestamp with time zone,
    contract_id uuid,
    profile_id uuid,
    marketing_region_id uuid
);
ALTER TABLE ONLY public.accounts
    ADD CONSTRAINT accounts_email_key UNIQUE (email);
ALTER TABLE ONLY public.accounts
    ADD CONSTRAINT accounts_pkey PRIMARY KEY (user_id);
ALTER TABLE ONLY public.attendance_config
    ADD CONSTRAINT attendance_config_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.attendance_records
    ADD CONSTRAINT attendance_records_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.branches
    ADD CONSTRAINT branches_name_key UNIQUE (name);
ALTER TABLE ONLY public.branches
    ADD CONSTRAINT branches_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.contracts
    ADD CONSTRAINT contracts_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.distributors
    ADD CONSTRAINT distributors_name_key UNIQUE (name);
ALTER TABLE ONLY public.distributors
    ADD CONSTRAINT distributors_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.distro_store_assignments
    ADD CONSTRAINT distro_store_assignments_branch_id_key UNIQUE (branch_id);
ALTER TABLE ONLY public.distro_store_assignments
    ADD CONSTRAINT distro_store_assignments_mate_store_id_key UNIQUE (mate_store_id);
ALTER TABLE ONLY public.distro_store_assignments
    ADD CONSTRAINT distro_store_assignments_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.inventories
    ADD CONSTRAINT inventories_branch_id_key UNIQUE (branch_id);
ALTER TABLE ONLY public.inventories
    ADD CONSTRAINT inventories_mate_store_id_key UNIQUE (mate_store_id);
ALTER TABLE ONLY public.inventories
    ADD CONSTRAINT inventories_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.locations
    ADD CONSTRAINT locations_geo_loc_key UNIQUE (geo_loc);
ALTER TABLE ONLY public.locations
    ADD CONSTRAINT locations_name_key UNIQUE (name);
ALTER TABLE ONLY public.locations
    ADD CONSTRAINT locations_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.marketing_regions
    ADD CONSTRAINT marketing_regions_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.marketing_regions
    ADD CONSTRAINT marketing_regions_region_code_key UNIQUE (region_code);
ALTER TABLE ONLY public.mate_stores
    ADD CONSTRAINT mate_stores_name_key UNIQUE (name);
ALTER TABLE ONLY public.mate_stores
    ADD CONSTRAINT mate_stores_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.product_pictures
    ADD CONSTRAINT product_attributes_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.product_categories
    ADD CONSTRAINT product_categories_name_key UNIQUE (name);
ALTER TABLE ONLY public.product_categories
    ADD CONSTRAINT product_categories_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.product_packagings
    ADD CONSTRAINT product_packagings_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_product_code_key UNIQUE (product_code);
ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_variant_key UNIQUE (variant);
ALTER TABLE ONLY public.user_pictures
    ADD CONSTRAINT user_pictures_account_id_key UNIQUE (account_id);
ALTER TABLE ONLY public.user_pictures
    ADD CONSTRAINT user_pictures_picture_url_key UNIQUE (picture_url);
ALTER TABLE ONLY public.user_pictures
    ADD CONSTRAINT user_pictures_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.user_profiles
    ADD CONSTRAINT user_profiles_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.user_profiles
    ADD CONSTRAINT user_profiles_user_id_key UNIQUE (user_id);
ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_account_id_key UNIQUE (account_id);
ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_government_id_key UNIQUE (government_id);
ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_marketing_region_id_key UNIQUE (marketing_region_id);
ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_profile_id_key UNIQUE (profile_id);
CREATE INDEX product_categories_name_idx ON public.product_categories USING gin (name public.gin_trgm_ops);
CREATE INDEX products_name_code_variant_idx ON public.products USING gin ((((((name || ' '::text) || product_code) || ' '::text) || variant)) public.gin_trgm_ops);
ALTER TABLE ONLY public.attendance_records
    ADD CONSTRAINT attendance_records_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounts(user_id) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE ONLY public.branches
    ADD CONSTRAINT branches_area_id_fkey FOREIGN KEY (area_id) REFERENCES public.marketing_regions(id) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE ONLY public.branches
    ADD CONSTRAINT branches_distributor_id_fkey FOREIGN KEY (distributor_id) REFERENCES public.distributors(id) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE ONLY public.branches
    ADD CONSTRAINT branches_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.locations(id) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE ONLY public.contracts
    ADD CONSTRAINT contracts_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE ONLY public.distributors
    ADD CONSTRAINT distributors_area_id_fkey FOREIGN KEY (area_id) REFERENCES public.marketing_regions(id) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE ONLY public.distro_store_assignments
    ADD CONSTRAINT distro_store_assignments_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES public.branches(id) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE ONLY public.distro_store_assignments
    ADD CONSTRAINT distro_store_assignments_mate_store_id_fkey FOREIGN KEY (mate_store_id) REFERENCES public.mate_stores(id) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE ONLY public.distro_store_assignments
    ADD CONSTRAINT distro_store_assignments_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE ONLY public.inventories
    ADD CONSTRAINT inventories_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES public.branches(id) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE ONLY public.inventories
    ADD CONSTRAINT inventories_id_fkey FOREIGN KEY (id) REFERENCES public.mate_stores(id) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE ONLY public.inventories
    ADD CONSTRAINT inventories_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE ONLY public.mate_stores
    ADD CONSTRAINT mate_stores_distributor_id_fkey FOREIGN KEY (supplier_id) REFERENCES public.distributors(id) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE ONLY public.mate_stores
    ADD CONSTRAINT mate_stores_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.locations(id) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE ONLY public.product_pictures
    ADD CONSTRAINT product_attributes_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.product_categories(id) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_packaging_id_fkey FOREIGN KEY (packaging_id) REFERENCES public.product_packagings(id) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE ONLY public.user_pictures
    ADD CONSTRAINT user_pictures_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounts(user_id) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE ONLY public.user_profiles
    ADD CONSTRAINT user_profiles_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounts(user_id) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_contract_id_fkey FOREIGN KEY (contract_id) REFERENCES public.contracts(id) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_marketing_region_id_fkey FOREIGN KEY (marketing_region_id) REFERENCES public.marketing_regions(id) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES public.user_profiles(id) ON UPDATE RESTRICT ON DELETE RESTRICT;
