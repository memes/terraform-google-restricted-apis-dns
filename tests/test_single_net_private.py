"""Test fixture for Private APIs DNS module with a single VPC network."""

import pathlib
import re
from collections.abc import Callable, Generator
from typing import Any, cast

import pytest

from .conftest import EXPECTED_DNS_ZONES, EXPECTED_PRIVATE_A_RRS, EXPECTED_PRIVATE_AAAA_RRS, run_tofu_in_workspace

FIXTURE_NAME = "single-net-private"
FIXTURE_LABELS = {
    "fixture": FIXTURE_NAME,
}


@pytest.fixture(scope="module")
def fixture_name(prefix: str) -> str:
    """Return the name to use for resources in this module."""
    return f"{prefix}-{FIXTURE_NAME}"


@pytest.fixture(scope="module")
def fixture_labels(labels: dict[str, str]) -> dict[str, str]:
    """Return a dict of labels for this test module."""
    return FIXTURE_LABELS | labels


@pytest.fixture(scope="module")
def vpcs_fixture_output(
    vpcs_fixture_dir: pathlib.Path,
    project_id: str,
    fixture_name: str,
) -> Generator[dict[str, Any], None, None]:
    """Create a VPC network for the test case."""
    with run_tofu_in_workspace(
        fixture=vpcs_fixture_dir,
        workspace=FIXTURE_NAME,
        tfvars={
            "project_id": project_id,
            "names": [
                fixture_name,
            ],
        },
    ) as output:
        yield output


@pytest.fixture(scope="module")
def network_self_links(vpcs_fixture_output: dict[str, Any]) -> list[str]:
    """Return a list of VPC network self-links for test fixture."""
    network_self_links = cast("list[str]", vpcs_fixture_output.get("self_links"))
    assert network_self_links
    assert len(network_self_links) == 1
    return network_self_links


@pytest.fixture(scope="module")
def fixture_output(
    root_fixture_dir: pathlib.Path,
    project_id: str,
    fixture_name: str,
    fixture_labels: dict[str, str],
    network_self_links: list[str],
) -> Generator[dict[str, Any], None, None]:
    """Create Restricted APIs DNS zone and records for test case."""
    with run_tofu_in_workspace(
        fixture=root_fixture_dir,
        workspace=FIXTURE_NAME,
        tfvars={
            "project_id": project_id,
            "name": fixture_name,
            "use_private_access_endpoints": True,
            "labels": fixture_labels,
            "network_self_links": network_self_links,
        },
    ) as output:
        yield output


def test_output_values(fixture_output: dict[str, Any]) -> None:
    """Verify the fixture output meets expectations."""
    assert fixture_output is not None
    assert fixture_output == {}


@pytest.fixture(scope="module")
def managed_zone_name_builder(fixture_name: str) -> Callable[[str], str]:
    """Return a builder of managed zone names for a domain."""

    def _builder(dns_zone: str) -> str:
        return f"{fixture_name}-{re.sub(r'[^a-zA-Z0-9]', '-', dns_zone[:-1])}"

    return _builder


@pytest.mark.parametrize("dns_zone", EXPECTED_DNS_ZONES)
def test_managed_zone(
    fixture_output: dict[str, Any],  # noqa: ARG001
    managed_zone_asserter: Callable[..., None],
    managed_zone_name_builder: Callable[[str], str],
    fixture_labels: dict[str, str],
    network_self_links: list[str],
    dns_zone: str,
) -> None:
    """Verify that the Cloud DNS managed zone for DNS domain matches expectations."""
    managed_zone_asserter(
        managed_zone_name=managed_zone_name_builder(dns_zone),
        expected_labels=fixture_labels,
        dns_zone=dns_zone,
        expected_network_self_links=network_self_links,
    )


@pytest.mark.parametrize("dns_zone", EXPECTED_DNS_ZONES)
def test_cname_record_set(
    fixture_output: dict[str, Any],  # noqa: ARG001
    resource_records_set_asserter: Callable[..., None],
    managed_zone_name_builder: Callable[[str], str],
    dns_zone: str,
) -> None:
    """Verify that the Cloud DNS CNAME resource records for the wildcard DNS domain matches expectations."""
    resource_records_set_asserter(
        managed_zone_name=managed_zone_name_builder(dns_zone),
        dns_zone=f"*.{dns_zone}",
        dns_type="CNAME",
        expected_rrdatas=[
            dns_zone,
        ],
    )


@pytest.mark.parametrize("dns_zone", EXPECTED_DNS_ZONES)
@pytest.mark.parametrize(
    ("dns_type", "expected_rrdatas"),
    [("A", EXPECTED_PRIVATE_A_RRS), ("AAAA", EXPECTED_PRIVATE_AAAA_RRS)],
)
def test_address_record_set(
    fixture_output: dict[str, Any],  # noqa: ARG001
    resource_records_set_asserter: Callable[..., None],
    managed_zone_name_builder: Callable[[str], str],
    dns_zone: str,
    dns_type: str,
    expected_rrdatas: list[str] | None,
) -> None:
    """Verify that the Cloud DNS address resource records for the DNS domain matches expectations."""
    resource_records_set_asserter(
        managed_zone_name=managed_zone_name_builder(dns_zone),
        dns_zone=dns_zone,
        dns_type=dns_type,
        expected_rrdatas=expected_rrdatas,
    )
