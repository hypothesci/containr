
#' Title
#'
#' @param image
#' @param system_deps
#' @param working_dir
#'
#' @return
#' @export
#'
#' @examples
docker_deploy <- function(image, system_deps = c(), working_dir = getwd()) {
	r_version <- R.Version()
	r_version_str <- paste0(r_version$major, ".", r_version$minor)

	r_deps <- c("r-base", "r-base-dev", "r-recommended")

	apt_deps <- c(
		"libcurl4-openssl-dev",
		"libxml2-dev",
		"libssl-dev",
		"locales",
		"wget",
		sapply(r_deps, function(d) paste0(d, "=", r_version_str, "-*")),
		system_deps
	)

	rscript <- function(code) {
		paste0("RUN Rscript -e \"", code, "\"")
	}

	context_dir <- file.path(tempdir(), uuid::UUIDgenerate(F))
	dir.create(context_dir)

	packrat_lockfile <- file.path(working_dir, "packrat", "packrat.lock")
	using_packrat <- file.exists(packrat_lockfile)

	if (using_packrat) {
		target_packrat_dir <- file.path(context_dir, "packrat")
		src_packrat_dir <- file.path(working_dir, "packrat")

		dir.create(target_packrat_dir)
		file.copy(packrat_lockfile, target_packrat_dir)

		docker_operations <- c(
			"COPY packrat packrat"
		)

		bootstrap_operations <- c(
			"install.packages('packrat')",
			"packrat::restore()",
			"packrat::packify()"
		)
	} else {
	  stop("Failed to locate Packrat lockfile")
	}

	bash_seq <- function(...) {
		paste0("RUN ", paste(list(...), collapse = " && "))
	}

	ubuntu_repo_suffix <- "xenial"

	if (r_version$major == "3") {
		r_minor_components <- strsplit(r_version$minor, ".", fixed = T)[[1]]
		if (as.integer(r_minor_components[[1]]) > 4) {
			ubuntu_repo_suffix <- "xenial-cran35"
		}
	}

	lines <- c(
		paste0("FROM ubuntu:16.04"),
		bash_seq(
			"apt-get update",
			"apt-get install -y apt-transport-https software-properties-common",
			"apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9",
			paste0("add-apt-repository 'deb https://cloud.r-project.org/bin/linux/ubuntu ", ubuntu_repo_suffix, "/'")
		),
		bash_seq(
			"apt-get update",
			paste0("apt-get install -y ", paste(apt_deps, collapse = " "))
		),
		bash_seq(
			"echo \"en_US.UTF-8 UTF8\" >> /etc/locale.gen",
			"locale-gen en_US.utf8",
			"/usr/sbin/update-locale LANG=en_US.UTF-8"
		),
		"ENV LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8",
		docker_operations,
		rscript(paste(bootstrap_operations, collapse = "; "))
	)

	writeLines(lines, con = file.path(context_dir, "Dockerfile"))

	build_status <- system(paste0("docker build -t ", image,  " ", context_dir))
	if (build_status != 0) stop("docker build failed")

	push_status <- system(paste0("docker push ", image))
	if (push_status != 0) stop("docker push failed")
}
