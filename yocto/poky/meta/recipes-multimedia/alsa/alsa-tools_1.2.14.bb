SUMMARY = "Advanced tools for certain ALSA sound card drivers"
DESCRIPTION = "Package containing a number of tools ranging from envy24control \
which provides complete control over all devices with an envy24 chip, to \
firmware loaders for pcmcia, USB and the hdsp devices."
HOMEPAGE = "http://www.alsa-project.org"
BUGTRACKER = "http://alsa-project.org/main/index.php/Bug_Tracking"
SECTION = "console/utils"
LICENSE = "GPL-2.0-only & LGPL-2.0-or-later"
DEPENDS = "alsa-lib"

LIC_FILES_CHKSUM = "file://hdsploader/COPYING;md5=59530bdf33659b29e73d4adb9f9f6552 \
                    file://ld10k1/COPYING.LIB;md5=a916467b91076e631dd8edb7424769c7 \
                    "

SRC_URI = "https://www.alsa-project.org/files/pub/tools/${BP}.tar.bz2"

SRC_URI[sha256sum] = "faef6fdd39ec79c9a5473dc63aa1b6331bf7664a9d452a0a8198cec7016cbc6f"

inherit autotools-brokensep pkgconfig
# brokensep as as10k1 (and probably more) fail out of tree
CLEANBROKEN = "1"

# Here we use PACKAGECONFIG options to pick which directories we configure/build.
# Remember on upgrades to check that no new tools have been added.
PACKAGECONFIG ??= "as10k1 hdajacksensetest hda-verb hdsploader ld10k1 mixartloader pcxhrloader \
                   sb16_csp seq--sbiload sscape_ctl us428control usx2yloader vxloader \
                   ${@bb.utils.contains_any('DISTRO_FEATURES', '${GTK3DISTROFEATURES}', 'hdajackretask', '', d)} \
                   "

PACKAGECONFIG[as10k1] = ""
PACKAGECONFIG[echomixer] = ",,gtk+"
PACKAGECONFIG[envy24control] = ",,gtk+"
PACKAGECONFIG[hda-verb] = ""
PACKAGECONFIG[hdajackretask] = ",,gtk+3"
PACKAGECONFIG[hdajacksensetest] = ",,glib-2.0"
PACKAGECONFIG[hdspconf] = ",,fltk"
PACKAGECONFIG[hdsploader] = ""
PACKAGECONFIG[hdspmixer] = ",,fltk"
PACKAGECONFIG[ld10k1] = ""
PACKAGECONFIG[mixartloader] = ""
PACKAGECONFIG[pcxhrloader] = ""
PACKAGECONFIG[qlo10k1] = ",,qt-x11-free"
PACKAGECONFIG[rmedigicontrol] = ",,gtk+"
PACKAGECONFIG[sb16_csp] = ""
PACKAGECONFIG[seq--sbiload] = ""
PACKAGECONFIG[sscape_ctl] = ""
PACKAGECONFIG[us428control] = ""
PACKAGECONFIG[usx2yloader] = ""
PACKAGECONFIG[vxloader] = ""

# At the time of writing pyalsa is not packaged for OE, so this is not expected
# to work.
PACKAGECONFIG[hwmixvolume] = ",,,python-core python-pygobject pyalsa"

python do_configure() {
    for subdir in d.getVar("PACKAGECONFIG").split():
        subdir = subdir.replace("--", "/")
        bb.note("Configuring %s" % subdir)
        dd = d.createCopy()
        dd.setVar("S", os.path.join(d.getVar("S"), subdir))
        bb.build.exec_func("autotools_do_configure", dd)
}

python do_compile() {
    for subdir in d.getVar("PACKAGECONFIG").split():
        subdir = subdir.replace("--", "/")
        bb.note("Compiling %s" % subdir)
        dd = d.createCopy()
        dd.setVar("S", os.path.join(d.getVar("S"), subdir))
        bb.build.exec_func("autotools_do_compile", dd)
}

python do_install() {
    d.delVarFlag("autotools_do_install", "cleandirs")
    for subdir in d.getVar("PACKAGECONFIG").split():
        subdir = subdir.replace("--", "/")
        bb.note("Installing %s" % subdir)
        dd = d.createCopy()
        dd.setVar("S", os.path.join(d.getVar("S"), subdir))
        bb.build.exec_func("autotools_do_install", dd)

    # Just remove bash-needing init script that isn't installed as an init script
    try:
        os.remove(oe.path.join(d.getVar("D"), d.getVar("sbindir"), "ld10k1d"))
    except:
        pass
}

FILES:${PN} += "${datadir}"
